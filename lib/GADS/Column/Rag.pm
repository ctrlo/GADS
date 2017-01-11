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

package GADS::Column::Rag;

use Log::Report;

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column::Code';

has '+type' => (
    default => 'rag',
);

has green => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        my ($rag) = $self->_rset->rags;
        $rag->green;
    },
);

has amber => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        my ($rag) = $self->_rset->rags;
        $rag->amber;
    },
);

has red => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        my ($rag) = $self->_rset->rags;
        $rag->red;
    },
);

after 'build_values' => sub {
    my ($self, $original) = @_;

    my ($rag) = $original->{rags}->[0];
    if ($rag) # RAG defined?
    {
        $self->green($rag->{green}),
        $self->amber($rag->{amber}),
        $self->red($rag->{red}),
    }
};

has unique_key => (
    is      => 'ro',
    default => 'ragval_ux_record_layout',
);

has '+table' => (
    default => 'Ragval',
);

has '+userinput' => (
    default => 0,
);

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Rag')->search({ layout_id => $id })->delete;
    $schema->resultset('Ragval')->search({ layout_id => $id })->delete;
}

+around 'write' => sub
{   my $orig = shift;

    my $guard = $_[0]->schema->txn_scope_guard;

    $orig->(@_); # Standard column write first

    my ($self, %options) = @_;

    my $no_alerts = $options{no_alerts};

    my $rag = {
        red   => $self->red,
        amber => $self->amber,
        green => $self->green,
    };
    my ($ragr) = $self->schema->resultset('Rag')->search({
        layout_id => $self->id
    })->all;
    my $need_update;
    if ($ragr)
    {
        # First see if the calculation has changed
        $need_update =  $ragr->red ne $self->red
                     || $ragr->amber ne $self->amber
                     || $ragr->green ne $self->green;
        $ragr->update($rag);
    }
    else {
        $rag->{layout_id} = $self->id;
        $self->schema->resultset('Rag')->create($rag);
        $need_update   = 1;
        $no_alerts = 1; # Don't alert on all new values
    }

    if ($need_update)
    {
        my %depends_on; # Stop duplicates

        foreach my $var ($self->params_red, $self->params_amber, $self->params_green)
        {
            my $col = $self->layout->column_by_name_short($var)
                or error __x"Unknown short column name \"{name}\" in calculation", name => $var;
            $depends_on{$col->id} = 1
                unless $col->internal;
        }

        my @depends_on = keys %depends_on;

        $self->depends_on(\@depends_on);
        $self->update_cached(no_alerts => $no_alerts)
            unless $options{no_cache_update};
    }

    $guard->commit;
};

sub clear
{   my $self = shift;
    $self->clear_red;
    $self->clear_amber;
    $self->clear_green;
}

sub params_red
{   my $self = shift;
    my $params = $self->_parse_code($self->red)->{params};
    @$params;
}

sub params_amber
{   my $self = shift;
    my $params = $self->_parse_code($self->amber)->{params};
    @$params;
}

sub params_green
{   my $self = shift;
    my $params = $self->_parse_code($self->green)->{params};
    @$params;
}

1;

