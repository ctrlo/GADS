
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

with 'GADS::Role::Presentation::Datum::Tree';

after set_value => sub {
    my ($self, $value) = @_;
    my $clone = $self->clone;    # Copy before changing text
    my @values =
        sort grep { $_ } ref $value eq 'ARRAY' ? @$value : ($value);
    my @old     = sort @{ $self->ids };
    my $changed = "@values" ne "@old";
    if ($changed)
    {
        my @text;
        foreach (@values)
        {
            $self->column->validate($_, fatal => 1);
            push @text, $self->column->node($_)->{value};
        }
        $self->clear_text;
        $self->clear_blank;
        $self->clear_ancestors;
        $self->clear_full_path;
        $self->text_all(\@text);
    }
    $self->changed($changed);
    $self->oldvalue($clone);
    $self->ids(\@values);
};

sub id { panic "id() removed for Tree datum" }

has ids => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->value_hash->{ids} || [];
    },
);

sub ids_as_params
{   my $self = shift;
    join '&', map { "ids=$_" } @{ $self->ids };
}

sub _build_blank
{   my $self = shift;
    !grep { $_ } @{ $self->ids };
}

# Make up for missing predicated value property
sub has_value { !$_[0]->blank || $_[0]->init_no_value }

sub html_form
{   my $self = shift;
    [ map { $_ || '' } @{ $self->ids } ];
}

has value_hash => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->has_init_value or return {
            ids  => [],
            text => [],
        };

       # XXX - messy to account for different initial values. Can be tidied once
       # we are no longer pre-fetching multiple records

        my @values = map {
            ref $_ eq 'HASH' && exists $_->{record_id}
                ? $_->{value}
                : $_
        } @{ $self->init_value };
        my (@ids, @texts);
        foreach (@values)
        {
            if (ref $_ eq 'HASH')
            {
                next if !$_->{id};
                push @ids,   $_->{id};
                push @texts, $_->{value} || '';
            }
            else
            {
                my $e = $self->column->node($_)
                    or next;
                push @ids,   $e && $e->{id};
                push @texts, $e && $e->{value};
            }
        }

        +{
            ids  => \@ids,
            text => \@texts,
        };
    },
);

has ancestors => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        my @return;
        foreach my $id (@{ $self->ids })
        {
            my $node = $self->column->node($id);
            my @ancestors =
                $node->{node} ? $node->{node}->{node}->ancestors : ();
            my @ancs;
            foreach my $anc (@ancestors)
            {
                my $node     = $self->column->node($anc->name);
                my $dag_node = $node->{node}->{node};
                push @ancs, $node
                    if $dag_node
                    && defined $dag_node->mother;    # Do not add root node
            }
            push @return, \@ancs;
        }
        \@return;
    },
);

has full_path => (
    is      => 'lazy',
    clearer => 1,
    builder => sub {
        my $self = shift;
        my @all;
        my @all_texts = @{ $self->text_all };
        foreach my $anc (@{ $self->ancestors })
        {
            my $text = shift @all_texts;
            my @path;
            push @path, $_->{value} foreach @$anc;
            my $path = join '#', @path;
            $path = $path ? "$path#" . $text : $text;
            push @all, $path;
        }
        return \@all;
    },
);

sub value_regex_test { shift->full_path }

has text => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        join ', ', @{ $self->text_all };
    },
);

# Internal text, array ref of all individual text values
has text_all => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    builder => sub {
        $_[0]->value_hash->{text} || [];
    },
);

sub for_table
{   my $self   = shift;
    my $return = $self->for_table_template;
    $return->{values} = [ $self->text_all ];
    $return;
}

around 'clone' => sub {
    my $orig       = shift;
    my $self       = shift;
    my %value_hash = (        # Ensure true copy
        ids  => [ @{ $self->value_hash->{ids} } ],
        text => [ @{ $self->value_hash->{text} } ],
    );
    $orig->(
        $self,
        ids        => $self->ids,
        text       => $self->text,
        value_hash => \%value_hash,
        @_,
    );
};

sub as_string
{   my $self = shift;
    $self->text // "";
}

sub as_integer
{   my $self = shift;
    panic "No integer value";
}

sub _build_for_code
{   my $self   = shift;
    my @values = map {
        my @parents =
              $self->column->node($_)
            ? $self->column->node($_)->{node}->{node}->ancestors
            : ();
        pop @parents;    # Remove root
        my $r = {
            value => $self->blank
            ? undef
            : $self->column->node($_)->{value},
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
    } @{ $self->ids };

    if ($self->column->multivalue || @values > 1)
    {
        return \@values;
    }
    else
    {
        # If the value is blank then still return a hash. This makes it easier
        # to use in Lua without having to test for the existence of a value
        # first
        my $ret = $values[0];
        $ret ||= {
            value   => undef,
            parents => {},
        };
        return $ret;
    }
}

1;
