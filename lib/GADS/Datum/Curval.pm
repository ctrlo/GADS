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
        $self->clear_text;
        $value = undef if !$value; # Can be empty string, generating warnings
        $self->column->validate($value, fatal => 1);
        $self->changed(1) if (!defined($self->id) && defined $value)
            || (!defined($value) && defined $self->id)
            || (defined $self->id && defined $value && $self->id != $value);
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
        my $value = $self->init_value->{value};
        my ($id, $text);
        # From database, with enumval table joined
        if (ref $value eq 'HASH')
        {
            my $record = GADS::Record->new(
                schema               => $self->column->schema,
                layout               => $self->column->layout_parent,
                user                 => undef,
                record               => $value->{record_single},
                linked_id            => $value->{linked_id},
                parent_id            => $value->{parent_id},
                columns_retrieved_do => $self->column->curval_fields,
            );
            $text = $self->column->_format_row($record)->{value};
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
    return $self->value_hash->{text} if $self->value_hash && !$self->has_set_value;
    $self->id or return '';
    my $v = $self->column->value($self->id);
    defined $v or error __x"Invalid Curval ID {id}", id => $self->id;
    $v->{value};
}

has id => (
    is        => 'rw',
    isa       => Maybe[Int],
    lazy      => 1,
    trigger   => sub { $_[0]->blank(defined $_[1] ? 0 : 1) },
    builder   => sub { $_[0]->value_hash && $_[0]->value_hash->{id} },
);

has has_id => (
    is  => 'rw',
    isa => Bool,
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

1;
