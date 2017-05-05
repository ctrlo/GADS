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

package GADS::Column::Calc;

use Log::Report 'linkspace';

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;
use Scalar::Util qw(looks_like_number);

extends 'GADS::Column::Code';

has '+type' => (
    default => 'calc',
);

sub _build__rset_code
{   my $self = shift;
    $self->_rset or return;
    my ($code) = $self->_rset->calcs;
    if (!$code)
    {
        $code = $self->schema->resultset('Calc')->new({});
    }
    return $code;
}

# Convert return format to database column field
sub _format_to_field
{   my $return_type = shift;
    $return_type eq 'date'
    ? 'value_date'
    : $return_type eq 'integer'
    ? 'value_int'
    : $return_type eq 'numeric'
    ? 'value_numeric'
    : 'value_text'
}

has unique_key => (
    is      => 'ro',
    default => 'calcval_ux_record_layout',
);

# Used to provide a blank template for row insertion
# (to blank existing values)
has '+blank_row' => (
    lazy => 1,
    builder => sub {
        {
            value_date    => undef,
            value_int     => undef,
            value_numeric => undef,
            value_text    => undef,
        };
    },
);

has '+table' => (
    default => 'Calcval',
);

has '+return_type' => (
    isa => sub {
        return unless $_[0];
        $_[0] =~ /(string|date|integer|numeric)/
            or error __x"Bad return type {type}", type => $_[0];
    },
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_rset_code && $self->_rset_code->return_format || 'string';
    },
);

has decimal_places => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_rset_code && $self->_rset_code->decimal_places;
    },
);

has '+value_field' => (
    default => sub {_format_to_field shift->return_type},
);

has '+string_storage' => (
    default => sub {shift->return_type eq 'string'},
);

has '+numeric' => (
    default => sub {
        my $self = shift;
        $self->return_type eq 'integer' || $self->return_type eq 'numeric';
    },
);

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Calc')->search({ layout_id => $id })->delete;
    $schema->resultset('Calcval')->search({ layout_id => $id })->delete;
}

# Returns whether an update is needed
sub write_code
{   my ($self, $layout_id) = @_;
    my $rset = $self->_rset_code;
    my $need_update = !$rset->in_storage
        || $self->_rset_code->code ne $self->code
        || $self->_rset_code->return_format ne $self->return_type;
    $rset->layout_id($layout_id);
    $rset->code($self->code);
    $rset->return_format($self->return_type);
    $rset->decimal_places($self->decimal_places);
    $rset->insert_or_update;
    return $need_update;
}

sub resultset_for_values
{   my $self = shift;
    return $self->schema->resultset('Calcval')->search({
        layout_id => $self->id,
    },{
        group_by  => 'me.'.$self->value_field,
    }) if $self->return_type eq 'string';
}

sub validate
{   my ($self, $value) = @_;
    return 1 if !$value;
    if ($self->return_type eq 'date')
    {
        return $self->parse_date($value);
    }
    elsif ($self->return_type eq 'integer')
    {
        return $value =~ /^[0-9]+$/;
    }
    elsif ($self->return_type eq 'numeric')
    {
        return looks_like_number($value);
    }
    return 1;
}

1;

