=pod
GADS - Globally Accessible Data Store
Copyright (C) 2014 Ctrl O Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

package GADS::Column::Code;

use GADS::AlertSend;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

use Inline 'Lua' => q{
    function lua_run(string, vars)
        local env = {}
        env["vars"] = vars

        env["ipairs"] = ipairs
        env["math"] = { floor = math.floor, min = math.min, max = math.max, abs = math.abs }
        env["os"] = { time = os.time, date = os.date }
        env["pairs"] = pairs
        env["table"] = { sort = table.sort, insert = table.insert }
        env["tonumber"] = tonumber

        func, err = load(string, nil, 't', env)
        ret = {}
        if err then
            ret["success"] = 0
            ret["error"] = err
            return ret
        end
        ret["success"] = 1
        ret["return"] = func()
        return ret
    end
};

extends 'GADS::Column';

has _rset_code => (
    is      => 'lazy',
);

has code => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        my $code = $self->_rset_code && $self->_rset_code->code;
        $code || '';
    },
);

sub clear
{   my $self = shift;
    $self->clear_code;
}

has write_cache => (
    is      => 'rw',
    default => 1,
);

has base_url => (
    is => 'rw',
);

has '+userinput' => (
    default => 0,
);

sub params
{   my $self = shift;
    $self->_params_from_code($self->code);
}

sub param_columns
{   my ($self, %options) = @_;
    grep {
        $_
    } map {
        $self->layout->column_by_name_short($_)
            or $options{is_fatal} && error __x"Unknown short column name \"{name}\" in calculation", name => $_;
    } $self->params;
}

sub update_cached
{   my ($self, %options) = @_;

    return unless $self->write_cache;

    # $@ may be the result of a previous Log::Report::Dispatcher::Try block (as
    # an object) and may evaluate to an empty string. If so, txn_scope_guard
    # warns as such, so undefine to prevent the warning
    undef $@;
    my $guard = $self->schema->txn_scope_guard;

    $self->clear; # Refresh calc for updated calculation
    my $layout = $self->layout;

    # Flag curval fields to retrieve all values whenever they are built. This
    # will ensure that as eaech row is retrieved, the curval will already have
    # all fields it requires (which are all expected to be present for the
    # calcval)
    $_->type eq 'curval' && $_->build_all_columns foreach $layout->all;

    my $records = GADS::Records->new(
        user         => $self->user,
        layout       => $layout,
        schema       => $self->schema,
        columns      => [@{$self->depends_on},$self->id],
    );

    my @changed;
    while (my $record = $records->single)
    {
        my $datum = $record->fields->{$self->id};
        $datum->re_evaluate;
        $datum->write_value;
        push @changed, $record->current_id if $datum->changed;
    }

    $guard->commit;

    return if $options{no_alert_send}; # E.g. new column, don't want to alert on all

    # Send any alerts
    my $alert_send = GADS::AlertSend->new(
        layout      => $self->layout,
        schema      => $self->schema,
        user        => $self->user,
        base_url    => $self->base_url,
        current_ids => \@changed,
        columns     => [$self->id],
    );
    $alert_send->process;
};

sub _params_from_code
{   my ($self, $code) = @_;
    my $params = $self->_parse_code($code)->{params};
    @$params;
}

sub _parse_code
{   my ($self, $code) = @_;
    $code =~ /^\s*function\s+evaluate\s*\(([A-Za-z0-9_,\s]+)\)(.*?)end\s*$/s
        or error "Invalid code definition: must contain function evaluate(...)";
    my @params   = split /[,\s]+/, $1;
    my $run_code = $2;
    +{
        code   => $run_code,
        params => [@params],
    };
}

sub eval
{   my ($self, $code, $vars) = @_;
    my $run_code = $self->_parse_code($code)->{code};
    my $mapping = '';
    $mapping .= qq($_ = vars["$_"]\n) foreach keys %$vars;
    $run_code = $mapping.$run_code;
    my $return = lua_run($run_code, $vars);
    # Make sure we're not returning anything funky (e.g. code refs)
    my $ret = defined $return->{return} && ''.$return->{return};
    my $err = $return->{error} && ''.$return->{error};
    no warnings "uninitialized";
    trace "Return value from Lua: $ret, error: $err";
    +{
        return => $ret,
        error  => $err,
    }
}

# Internal flag to store whether we should send alerts after update
has _no_alerts => (
    is      => 'rw',
    isa     => Bool,
    clearer => 1,
);

sub write_special
{   my ($self, %options) = @_;

    my $id   = $options{id};
    my $rset = $options{rset};

    my $new = !$id || !$self->_rset_code->code;

    if ($self->write_code($id)) # Returns true if anything relevant changed
    {
        $self->_no_alerts(1) if $new;

        # Stop duplicates
        my %depends_on = map { $_->id => 1 } grep { !$_->internal } $self->param_columns(is_fatal => 1);
        my @depends_on = keys %depends_on;

        $self->schema->resultset('LayoutDepend')->search({
            layout_id => $id
        })->delete;
        foreach (@depends_on)
        {
            $self->schema->resultset('LayoutDepend')->create({
                layout_id  => $id,
                depends_on => $_,
            });
        }
        $self->clear_depends_on;

    }
};

# We don't really want to do this within a transaction as it can take a
# significantly long time, so do once the transaction has completed
sub after_write_special
{   my ($self, %options) = @_;
    $self->update_cached(no_alerts => $self->_no_alerts)
        unless $options{no_cache_update};
    $self->_clear_no_alerts;
}

1;
