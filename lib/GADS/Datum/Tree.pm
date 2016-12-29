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

package GADS::Datum::Tree;

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;
use namespace::clean;

extends 'GADS::Datum';

has set_value => (
    is       => 'rw',
    trigger  => sub {
        my ($self, $value) = @_;
        my $clone = $self->clone; # Copy before changing text
        $value = undef if !$value; # Can be empty string, generating warnings
        $self->column->validate($value, fatal => 1);
        # Look up text value
        my $node = $self->column->node($value);
        $self->text($node->{value}) if $node;
        $self->changed(1) if (!defined($self->id) && defined $value)
            || (!defined($value) && defined $self->id)
            || (defined $self->id && defined $value && $self->id != $value);
        $self->id($value);
        $self->oldvalue($clone);
    },
);

has id => (
    is      => 'rw',
    lazy    => 1,
    trigger => sub { $_[0]->blank(defined $_[1] ? 0 : 1) },
    builder => sub {
        $_[0]->value_hash->{id};
    },
);

has has_id => (
    is  => 'rw',
    isa => Bool,
);

sub value { $_[0]->id }

# Make up for missing predicated value property
sub has_value { $_[0]->has_id }

has value_hash => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->has_init_value or return {};
        my $value = $self->init_value->{value};
        my $id = $value->{id};
        $self->has_id(1) if defined $id || $self->init_no_value;
        +{
            id      => $id,
            text    => $value->{value},
            deleted => $value->{deleted},
        };
    },
);

has ancestors => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my $node = $self->column->node($self->id);
        my @ancestors = $node->{node} ? $node->{node}->{node}->ancestors : ();
        my @return;
        foreach my $anc (@ancestors)
        {
            my $node     = $self->column->node($anc->name);
            my $dag_node = $node->{node}->{node};
            push @return, $node if $dag_node && defined $dag_node->mother; # Do not add root node
        }
        \@return;
    },
);

has full_path => (
    is => 'rw',
    lazy => 1,
    builder => sub {
        my $self = shift;
        my @path;
        push @path, $_->{value}
            foreach @{$self->ancestors};
        my $path = join '#', @path;
        return $path ? "$path#".$self->text : $self->text;
    },
);

has text => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->value_hash->{text};
    },
);

has deleted => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->value_hash->{deleted};
    },
);

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self,
        id      => $self->id,
        text    => $self->text,
        deleted => $self->deleted,
    );
};

sub as_string
{   my $self = shift;
    $self->text // "";
}

sub as_integer
{   my $self = shift;
    $self->id // 0;
}

1;
