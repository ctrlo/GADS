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

use DateTime;
use Date::Holidays::GB qw/ is_gb_holiday gb_holidays /;
use GADS::AlertSend;
use JSON qw(decode_json encode_json);
use Log::Report 'linkspace';
use MIME::Base64 qw/encode_base64/;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

use Inline 'Lua' => q{
    function lua_run(string, vars, working_days_diff, working_days_add)
        local env = {}
        env["vars"] = vars

        env["working_days_diff"] = working_days_diff
        env["working_days_add"] = working_days_add

        env["ipairs"] = ipairs
        env["math"] = {
            abs = math.abs,
            acos = math.acos,
            asin = math.asin,
            atan = math.atan,
            atan2 = math.atan2,
            ceil = math.ceil,
            cos = math.cos,
            cosh = math.cosh,
            deg = math.deg,
            exp = math.exp,
            floor = math.floor,
            fmod = math.fmod,
            frexp = math.frexp,
            huge = math.huge,
            ldexp = math.ldexp,
            log = math.log,
            log10 = math.log10,
            max = math.max,
            min = math.min,
            modf = math.modf,
            pi = math.pi,
            pow = math.pow,
            rad = math.rad,
            random = math.random,
            sin = math.sin,
            sinh = math.sinh,
            sqrt = math.sqrt,
            tan = math.tan,
            tanh = math.tanh
        }
        env["next"] = next
        env["os"] = {
            clock = os.clock,
            date = os.date,
            difftime = os.difftime,
            time = os.time
        }
        env["pairs"] = pairs
        env["pcall"] = pcall
        env["select"] = select
        env["string"] = {
            byte = string.byte,
            char = string.char,
            find = string.find,
            format = string.format,
            gmatch = string.gmatch,
            gsub = string.gsub,
            len = string.len,
            lower = string.lower,
            match = string.match,
            rep = string.rep,
            reverse = string.reverse,
            sub = string.sub,
            upper = string.upper
        }
        env["table"] = {
            insert = table.insert,
            maxn = table.maxn,
            remove = table.remove,
            sort = table.sort
        }
        env["tonumber"] = tonumber
        env["tostring"] = tostring
        env["type"] = type
        env["unpack"] = unpack

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
    clearer => 1,
);

sub _build_has_browser_code {
    #In theory this should remain the same - the value of show_in_edit is actually the one that defines if the field is "hidden" or not
    my $self = shift;
    return 1 if $self->show_in_edit;
    return 1 if $self->schema->resultset('DisplayField')->search({
        display_field_id => $self->id
    })->next;
    return 0;
}

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

sub code_b64
{   my $self = shift;
    encode_base64($self->code, '');
}

sub clear
{   my $self = shift;
    $self->clear_code;
}

has write_cache => (
    is      => 'rw',
    default => 1,
);

has '+userinput' => (
    default => 0,
);

has '+has_cache' => (
    default => 1,
);

sub table_unique {}

sub params
{   my $self = shift;
    $self->_params_from_code($self->code);
}

sub params_b64
{   my $self = shift;
    encode_base64(encode_json([$self->params]), '');
}

sub param_columns
{   my ($self, %options) = @_;
    grep {
        $_
    } map {
        my $col = $self->layout->column_by_name_short($_)
            or $options{is_fatal} && error __x"Unknown short column name \"{name}\" in calculation", name => $_;
        $col->instance_id == $self->instance_id
            or $options{is_fatal} && error __x"It is only possible to use fields from the same table ({table1}). \"{name}\" is from {table2}.",
                name => $_, table1 => $self->layout->name, table2 => $col->layout->name;
        $col;
    } $self->params;
}

sub update_cached
{   my ($self, %options) = @_;

    return unless $self->write_cache;

    # $@ may be the result of a previous Log::Report::Dispatcher::Try block (as
    # an object) and may evaluate to an empty string. If so, txn_scope_guard
    # warns as such, so undefine to prevent the warning
    undef $@;

    $self->clear; # Refresh calc for updated calculation
    my $layout = $self->layout;

    local $GADS::Schema::IGNORE_PERMISSIONS = 1;

    my $records = GADS::Records->new(
        user                    => undef,
        layout                  => $layout,
        schema                  => $self->schema,
        columns                 => [@{$self->depends_on},$self->id],
        ignore_view_limit_extra => 1,
        include_children        => 1, # Update all child records regardless
    );

    my @changed;
    while (my $record = $records->single)
    {
        my $datum = $record->fields->{$self->id};
        $datum->re_evaluate(no_errors => 1);
        $datum->write_value;
        push @changed, $record->current_id if $datum->changed;
    }

    return if $options{no_alert_send}; # E.g. new column, don't want to alert on all

    # Send any alerts
    my $alert_send = GADS::AlertSend->new(
        layout      => $self->layout,
        schema      => $self->schema,
        user        => $self->user,
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
    !$code || $code =~ /^\s*function\s+evaluate\s*\(([A-Za-z0-9_,\s]+)\)(.*?)end\s*$/s
        or error "Invalid code definition: must contain function evaluate(...)";
    my @params;
    @params   = split /[,\s]+/, $1
        if $1;
    my $run_code = $2;
    +{
        code   => $run_code,
        params => [@params],
    };
}

# XXX These functions can raise exceptions - further investigation needed as to
# whether this causes problems when called from Lua. Initial experience
# suggests it might do.
sub working_days_diff
{   my ($start_epoch, $end_epoch, $country, $region) = @_;

    @_ == 4
        or error "Parameters for working_days_diff need to be: start, end, country, region";

    $country eq 'GB' or error "Only country GB is currently supported";

    $start_epoch or error "Start date missing for working_days_diff";
    $end_epoch or error "End date missing for working_days_diff";

    my $start = DateTime->from_epoch(epoch => $start_epoch);
    my $end = DateTime->from_epoch(epoch => $end_epoch);

    # Check that we have the holidays for the years requested
    my $min = $start < $end ? $start->year : $end->year;
    my $max = $end > $start ? $end->year : $start->year;
    foreach my $year ($min..$max)
    {
        error __x"No bank holiday information available for year {year}", year => $year
            if !%{gb_holidays(year => $year, regions => [$region])};
    }

    my $days = 0;

    if ($end > $start)
    {
        my $marker = $start->clone->add(days => 1);

        while ($marker <= $end)
        {
            if (!is_gb_holiday(
                    year    => $marker->year, month => $marker->month, day => $marker->day,
                    regions => [$region] )
            ) {
                $days++ unless $marker->day_of_week == 6 || $marker->day_of_week == 7;
            }
            $marker->add(days => 1);
        }
    }
    else {
        my $marker = $start->clone->subtract(days => 1);

        while ($marker >= $end)
        {
            if (!is_gb_holiday(
                    year => $marker->year, month => $marker->month, day => $marker->day,
                    regions => [$region] )
            ) {
                $days-- unless $marker->day_of_week == 6 || $marker->day_of_week == 7;
            }
            $marker->subtract(days => 1);
        }
    }

    return $days;
}

sub working_days_add
{   my ($start_epoch, $days, $country, $region) = @_;

    @_ == 4
        or error "Parameters for working_days_add need to be: start, end, country, region";

    $country eq 'GB' or error "Only country GB is currently supported";
    $start_epoch or error "Date missing for working_days_add";

    my $start = DateTime->from_epoch(epoch => $start_epoch);

    error __x"No bank holiday information available for year {year}", year => $start->year
        if !%{gb_holidays(year => $start->year, regions => [$region])};

    while ($days)
    {
        $start->add(days => 1);
	if (!is_gb_holiday(
		year => $start->year, month => $start->month, day => $start->day,
		regions => [$region] )
	) {
	    $days-- unless $start->day_of_week == 6 || $start->day_of_week == 7;
	}
    }

    return $start->epoch;
}

# Flatten daterange return value
sub _flatten
{   my ($self, $val) = @_;
    return if ! defined $val;
    return +{
        from => "$val->{from}",
        to   => "$val->{to}",
    } if $self->return_type eq 'daterange';
    return "$val";
}

sub eval
{   my ($self, $code, $vars) = @_;
    my $run_code = $self->_parse_code($code)->{code};
    my $mapping = '';
    $mapping .= qq($_ = vars["$_"]\n) foreach keys %$vars;
    $run_code = $mapping.$run_code;
    my $return = lua_run($run_code, $vars, \&working_days_diff, \&working_days_add);
    # Make sure we're not returning anything funky (e.g. code refs)
    my $ret = $return->{return};
    if ($self->multivalue && ref $ret eq 'ARRAY')
    {
        $ret = [ map { $self->_flatten($_) } @$ret ];
    }
    elsif (defined $ret) {
        $ret = $self->_flatten($ret);
    }
    my $err = $return->{error} && ''.$return->{error};
    no warnings "uninitialized";
    trace "Return value from Lua: $ret, error: $err";
    +{
        return => $ret,
        error  => $err,
        code   => $run_code,
    }
}

sub write_special
{   my ($self, %options) = @_;

    my $id   = $options{id};
    my $rset = $options{rset};

    # rset_code may have been built before the rset property had been
    # initialised
    $self->_clear_rset_code;
    my $new = !$id || !$self->_rset_code->code;

    # It is not uncommon for users to accidentally copy auto-corrected
    # characters such as "smart quotes". These then result in a rather vague
    # Lua error about invalid char values. Instead, let's disallow all extended
    # characters, and give the user a sensible error.
    $self->code =~ /(.....[^\x00-\x7F]+.....)/
        and error __x"Extended characters are not supported in calculated fields (found here: {here})",
            here => $1;

    my %return_options;
    my $changed = $self->write_code($id, %options); # Returns true if anything relevant changed
    my $update_deps = exists $options{update_dependents} ? $options{update_dependents} : $changed;
    if ($update_deps)
    {
        $return_options{no_alerts} = 1 if $new;

        # Stop duplicates
        my %depends_on = map { $_->id => 1 } grep { !$_->internal } $self->param_columns(is_fatal => $options{override} ? 0 : 1);
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
    else {
        # If nothing has changed then do not update all values. That is, unless
        # no_cache_update has been explicitly specified (as it would be for a
        # user update of the field in manage fields) in which case keep that
        # value. That is so that a user can force update a calc field, even if
        # nothing has changed (the user may have previously changed the
        # calculation and now want to update all values)
        $return_options{no_cache_update} = 1
            unless exists $options{no_cache_update};
    }
    return %return_options;
};

# We don't really want to do this within a transaction as it can take a
# significantly long time, so do once the transaction has completed
sub after_write_special
{   my ($self, %options) = @_;
    $self->update_cached(no_alerts => $options{no_alerts})
        unless $options{no_cache_update};
}

1;
