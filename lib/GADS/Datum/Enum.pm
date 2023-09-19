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

package GADS::Datum::Enum;

use HTML::Entities qw/encode_entities/;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;
use namespace::clean;

extends 'GADS::Datum';

with 'GADS::Role::Presentation::Datum::Enum';

after set_value => sub {
    my ($self, $value) = @_;
    my $clone = $self->clone; # Copy before changing text
    my @values = sort grep {$_} ref $value eq 'ARRAY' ? @$value : ($value);
    my @old    = sort ref $self->id eq 'ARRAY' ? @{$self->id} : $self->id ? $self->id : ();
    my $changed = "@values" ne "@old";
    if ($changed)
    {
        my @text; my @deleted;
        foreach (@values)
        {
            $self->column->validate($_, fatal => 1);
            push @text, $self->column->enumval($_)->{value};
            push @deleted, $self->column->enumval($_)->{deleted};
        }
        $self->clear_text;
        $self->clear_text_all;
        $self->value_hash({
            ids     => \@values,
            text    => \@text,
            deleted => \@deleted,
        });
    }
    $self->changed($changed);
    $self->oldvalue($clone);
    $self->id($self->column->multivalue ? \@values : $values[0]);
};

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
    clearer => 1,
    builder => sub {
        $_[0]->value_hash->{text} || [];
    }
);

sub for_table
{   my $self = shift;
    my $return = $self->for_table_template;
    $return->{values} = $self->text_all;
    $return;
}

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

sub ids {
    my $self = shift;
    $self->column->multivalue ? $self->id : [ $self->id ];
}

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

has value_hash => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        # XXX - messy to account for different initial values. Can be tidied once
        # we are no longer pre-fetching multiple records
        my @init_value = $self->has_init_value ? @{$self->init_value} : ();
        my @values     = map { ref $_ eq 'HASH' && exists $_->{record_id} ? $_->{value} : $_ } @init_value;
        my (@ids, @texts, @deleted);
        foreach (@values)
        {
            if (ref $_ eq 'HASH')
            {
                push @ids, $_->{id};
                push @texts, $_->{value} || '';
                push @deleted, $_->{deleted};
            }
            else {
                my $e = $self->column->enumval($_)
                    or next;
                push @ids, $e && $e->{id};
                push @texts, $e && $e->{value};
                push @deleted, $e && $e->{deleted};
            }
        }
        $self->has_id(1) if (grep { defined $_ } @ids) || $self->init_no_value;
        +{
            ids     => \@ids,
            text    => \@texts,
            deleted => \@deleted, # Whether it is a value that has since been deleted
        };
    },
);

has has_id => (
    is  => 'rw',
    isa => Bool,
);

has id_hash => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_id_hash
{   my $self = shift;
    return $self->id ? { $self->id => 1 } : {} if !$self->column->multivalue;
    return {} if !$self->id;
    +{ map { $_ => 1 } @{$self->id} };
}

has deleted_values => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_deleted_values
{   my $self = shift;
    my @ids     = @{$self->value_hash->{ids}};
    my @deleted = @{$self->value_hash->{deleted}};
    my @text    = @{$self->value_hash->{text}};
    my @return;
    foreach my $id (@ids)
    {
        my $text = shift @text;
        next unless shift @deleted;
        push @return, {
            id          => $id,
            value       => $text,
            html        => encode_entities($text), # Needed for edit form render
            selector_id => $id,
            value_id    => $id,
        };
    }
    return \@return;
}

sub value { $_[0]->id }

# Make up for missing predicated value property
sub has_value { $_[0]->has_id }

sub html_form
{   my $self = shift;
    [ map { $_ || '' } $self->column->multivalue ? @{$self->id} : $self->id ];
}

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    my %value_hash = ( # Ensure true copy
        ids     => [@{$self->value_hash->{ids}}],
        text    => [@{$self->value_hash->{text}}],
        deleted => [@{$self->value_hash->{deleted}}],
    );
    $orig->($self, id => $self->id, text => $self->text, value_hash => \%value_hash, @_);
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

sub _build_for_code
{   my ($self, %options) = @_;

    my @ids   = @{$self->value_hash->{ids}};
    my @texts = @{$self->value_hash->{text}};

    my @values;
    foreach my $id (@ids)
    {
        push @values, {
            id    => $id,
            value => pop @texts,
        };
    }

    if (!$self->column->multivalue && @values <= 1)
    {
        return undef if $self->blank;
        return $self->as_string;
    }

    +{
        text   => $self->as_string,
        values => \@values,
    };

}

1;
