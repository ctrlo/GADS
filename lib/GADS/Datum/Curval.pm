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

package GADS::Datum::Curval;

use Log::Report;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Datum';

has set_value => (
    is       => 'rw',
    predicate => 1,
    trigger  => sub {
        my ($self, $value) = @_;
        my $clone = $self->clone; # Copy before changing text
        ($value) = @$value if ref $value eq 'ARRAY';
        $value = undef if !$value; # Can be empty string, generating warnings
        $self->column->validate($value, fatal => 1);
        $self->changed(1) if (!defined($self->id) && defined $value)
            || (!defined($value) && defined $self->id)
            || (defined $self->id && defined $value && $self->id != $value);
        if ($self->changed)
        {
            # Need to clear initial values, to ensure new value is built from this new ID
            $self->clear_text;
            $self->clear_init_value;
            $self->clear_value_hash;
        }
        $self->id($value);
        $self->oldvalue($clone);
    },
);

has value_hash => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1, # Clear when new value written
    builder => sub {
        my $self = shift;
        $self->has_init_value or return;
        my $value = $self->init_value->[0]->{value};
        my ($id, $text);
        # From database, with enumval table joined
        if (ref $value eq 'HASH')
        {
            $id = $value->{id};
        }
        else {
            return;
        }
        $self->has_id(1) if defined $id || $self->init_no_value;
        +{
            id   => $id,
            text => $text,
        };
    },
);

has _record => (
    is      => 'lazy',
    clearer => 1,
);

sub _build__record
{   my $self = shift;
    $self->has_init_value or return;
    my $value = $self->init_value->[0]->{value};
    GADS::Record->new(
        schema               => $self->column->schema,
        layout               => $self->column->layout_parent,
        user                 => undef,
        record               => $value->{record_single},
        linked_id            => $value->{linked_id},
        parent_id            => $value->{parent_id},
        columns_retrieved_do => $self->column->curval_fields_retrieve,
    );
}

has text => (
    is        => 'rwp',
    isa       => Str,
    lazy      => 1,
    builder   => 1,
    clearer   => 1,
    predicate => 1,
);

sub _build_text
{   my $self = shift;
    $self->id or return '';
    if ($self->_record)
    {
        my $record = $self->_record;
        return $self->column->_format_row($record)->{value};
    }
    my $v = $self->column->value($self->id);
    defined $v or error __x"Invalid Curval ID {id}", id => $self->id;
    $v->{value};
}

has id => (
    is        => 'rw',
    isa       => Maybe[Int],
    lazy      => 1,
    trigger   => sub { $_[0]->blank(defined $_[1] ? 0 : 1) },
    builder   => sub {
        my $self = shift;
        $self->has_init_value or return;
        my $id = $self->init_value->[0]->{value}->{id};
        $self->has_id(1) if defined $id || $self->init_no_value;
        return $id;
    },
);

has has_id => (
    is  => 'rw',
    isa => Bool,
);

has built_with_all => (
    is      => 'rwp',
    isa     => Bool,
    default => 0,
);

sub value { $_[0]->id }

# Make up for missing predicated value property
sub has_value { $_[0]->has_id }

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    # Only pass text in if it's already been built
    my %params = (
        id => $self->id,
    );
    $params{text} = $self->text if $self->has_text;
    $params{init_value} = $self->init_value if $self->has_init_value;
    $orig->($self, %params);
};

sub as_string
{   my $self = shift;
    $self->text // "";
}

sub as_integer
{   my $self = shift;
    $self->id // 0;
}

sub html_withlinks
{   my $self = shift;
    my $string = $self->as_string
        or return "";
    my $link = "/record/".$self->id."?oi=".$self->column->refers_to_instance;
    qq(<a href="$link">$string</a>);
}

sub for_code
{   my ($self, %options) = @_;
    my %value = $self->_record ? (row => $self->_record) : (id => $self->id);
    my $field_values = $self->column->field_values(%value);
    my $record = $self->_record;
    +{
        value        => $self->as_string,
        field_values => $field_values,
    };

}

1;
