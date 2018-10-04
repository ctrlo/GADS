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

use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;
use namespace::clean;

extends 'GADS::Datum';

after set_value => sub {
    my ($self, $value) = @_;
    my $clone = $self->clone; # Copy before changing text
    my @values = sort grep {$_} ref $value eq 'ARRAY' ? @$value : ($value);
    my @old    = sort ref $self->id eq 'ARRAY' ? @{$self->id} : $self->id ? $self->id : ();
    my $changed = "@values" ne "@old";
    if ($changed)
    {
        my @text;
        foreach (@values)
        {
            $self->column->validate($_, fatal => 1);
            push @text, $self->column->enumval($_)->{value};
        }
        $self->clear_text;
        $self->text_all(\@text);
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
    builder => sub {
        $_[0]->value_hash->{text} || [];
    }
);

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
    $orig->($self, id => $self->id, text => $self->text, @_);
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
{   my ($self, %options) = @_;
    if (!$self->column->multivalue)
    {
        return undef if $self->blank;
        return $self->as_string;
    }
    my %values;
    @values{@{$self->id}} = @{$self->text_all};
    +{
        text   => $self->as_string,
        values => \%values,
    };

}

1;
