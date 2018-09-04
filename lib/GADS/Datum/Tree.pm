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

use Log::Report;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Datum';

after set_value => sub {
    my ($self, $value) = @_;
    my $clone = $self->clone; # Copy before changing text
    my @values = sort grep {$_} ref $value eq 'ARRAY' ? @$value : ($value);
    my @old    = sort ref $self->id eq 'ARRAY' ? @{$self->id} : $self->id ? $self->id : ();
    my $changed = "@values" ne "@old";
    $self->_set_written_valid(!!@values);
    if ($changed)
    {
        my @text;
        foreach (@values)
        {
            $self->column->validate($_, fatal => 1);
            push @text, $self->column->node($_)->{value};
        }
        $self->clear_text;
        $self->text_all(\@text);
    }
    $self->changed($changed);
    $self->oldvalue($clone);
    $self->id($self->column->multivalue ? \@values : $values[0]);
};

has id => (
    is      => 'rw',
    isa     => sub {
        my $value = shift;
        !defined $value and return;
        ref $value ne 'ARRAY' && $value =~ /^[0-9]+/ and return;
        my @values = @$value;
        my @remain = grep {
            !defined $_ || $_ !~ /^[0-9]+$/;
        } @values and panic "Invalid value for ID";
    },
    lazy    => 1,
    trigger => sub {
        my $self = shift;
        $self->clear_blank;
    },
    builder => sub {
        my $self = shift;
        $self->column->multivalue
            ? [ grep { defined $_ } @{$self->value_hash->{ids}} ]
            : $self->value_hash->{ids}->[0];
    },
);

has has_id => (
    is  => 'rw',
    isa => Bool,
);

sub ids {
    my $self = shift;
    $self->column->multivalue ? $self->id : [ $self->id ];
}

sub ids_as_params
{   my $self = shift;
    join '&', map { "ids=$_" } @{$self->ids};
}

sub value { $_[0]->id }

sub _build_blank
{   my $self = shift;
    if ($self->column->multivalue)
    {
        @{$self->id} == 0 ? 1 : 0;
    }
    else {
        defined $self->id ? 0 : 1;
    }
}

# Make up for missing predicated value property
sub has_value { $_[0]->has_id }

sub html_form
{   my $self = shift;
    [ map { $_ || '' } $self->column->multivalue ? @{$self->id} : $self->id ];
}

has value_hash => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->has_init_value or return {};
        # XXX - messy to account for different initial values. Can be tidied once
        # we are no longer pre-fetching multiple records
        my @values = map { exists $_->{record_id} ? $_->{value} : $_ } @{$self->init_value};
        my @ids    = map { $_->{id} } @values;
        my @texts  = map { $_->{value} || '' } @values;
        $self->has_id(1) if (grep { defined $_ } @ids) || $self->init_no_value;
        +{
            ids  => \@ids,
            text => \@texts,
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

sub value_regex_test
{   shift->full_path }

has text => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        join ', ', @{$self->text_all};
    },
);

# Internal text, array ref of all individual text values
has text_all => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    builder => sub {
        $_[0]->value_hash->{text} || [];
    }
);

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self,
        id      => $self->id,
        text    => $self->text,
        @_,
    );
};

sub as_string
{   my $self = shift;
    $self->text // "";
}

sub as_integer
{   my $self = shift;
    panic "No integer value for multivalue"
        if $self->column->multivalue;
    $self->id // 0;
}

sub for_code
{   my $self = shift;
    my @values = map {
        my @parents = $self->column->node($_)
            ? $self->column->node($_)->{node}->{node}->ancestors
            : ();
        pop @parents; # Remove root
        my $r = {
            value   => $self->blank ? undef : $self->column->node($_)->{value},
            parents => {},
        };
        my $count;
        foreach my $parent (reverse @parents)
        {
            $count++;
            my $node_id = $parent->name;
            my $text    = $self->column->node($node_id)->{value};
            # Use text for the parent number, as this will not work in Lua:
            # value.parents.1
            $r->{parents}->{"parent$count"} = $text;
        }
        $r;
    } @{$self->ids};

    $self->column->multivalue ? \@values : $values[0];
}

1;
