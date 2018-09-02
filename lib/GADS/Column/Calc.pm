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

has 'has_filter_typeahead' => (
    is      => 'lazy',
);

sub _build_has_filter_typeahead
{   my $self = shift;
    $self->return_type eq 'string' ? 1 : 0;
}

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
    : 'value_text' # includes globe data type
}

has unique_key => (
    is      => 'ro',
    default => 'calcval_ux_record_layout',
);

has '+can_multivalue' => (
    default => 1,
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
        $_[0] =~ /(string|date|integer|numeric|globe)/
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
    default => sub {shift->value_field eq 'value_text'},
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
    }) if $self->value_field eq 'value_text';
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
        return $value =~ /^-?[0-9]+$/;
    }
    elsif ($self->return_type eq 'numeric')
    {
        return looks_like_number($value);
    }
    return 1;
}

before import_hash => sub {
    my ($self, $values, %options) = @_;
    my $report = $options{report_only} && $self->id;
    notice __x"Update: code has been changed"
        if $report && $self->code ne $values->{code};
    $self->code($values->{code});
    notice __x"Update: return_type from {old} to {new}", old => $self->return_type, new => $values->{return_type}
        if $report && $self->return_type ne $values->{return_type};
    $self->return_type($values->{return_type});
    notice __x"Update: decimal_places from {old} to {new}", old => $self->decimal_places, new => $values->{decimal_places}
        if $report && $self->return_type eq 'numeric' && (
            (defined $self->decimal_places xor defined $values->{decimal_places})
            || (defined $self->decimal_places && defined $values->{decimal_places} && $self->decimal_places != $values->{decimal_places})
        );
    $self->decimal_places($values->{decimal_places});
};

around export_hash => sub {
    my $orig = shift;
    my ($self, $values) = @_;
    my $hash = $orig->(@_);
    $hash->{code}           = $self->code;
    $hash->{return_type}    = $self->return_type;
    $hash->{decimal_places} = $self->decimal_places;
    return $hash;
};

1;

