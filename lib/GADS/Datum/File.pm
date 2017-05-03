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

package GADS::Datum::File;

use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;
use namespace::clean;

extends 'GADS::Datum';

sub set_value
{   my ($self, $value) = @_;
    my $clone = $self->clone; # Copy before changing text
    my $new_id;
    # If an array, $value will either be blank string (no file submitted, empty hidden value),
    # or 2 values, one the value and one blank
    if (ref $value eq 'ARRAY')
    {
        if (@$value > 1)
        {
            ($value) = grep { $_ } @$value;
        }
        else {
            ($value) = @$value;
        }
    }
    if (ref $value && $value->{content})
    {
        # New file uploaded
        $new_id = $self->schema->resultset('Fileval')->create({
            name     => $value->{name},
            mimetype => $value->{mimetype},
            content  => $value->{content},
        })->id;
        $self->content($value->{content});
        $self->name($value->{name});
        $self->mimetype($value->{mimetype});
        $self->_set_written_valid(1);
    }
    else {
        # Just ID for file passed. Probably a resubmission
        # of a form with previous errors
        $new_id = $value || undef;
        $self->_set_written_valid(!!$new_id);
    }
    $self->changed(1) if (!$self->id && $value)
        || (!$value && $self->id)
        || (defined $self->id && defined $new_id && $self->id != $new_id && $clone->content ne $self->content);
    $self->oldvalue($clone);
    $self->id($new_id) if defined $new_id || $self->init_no_value;
    $self->_set_written_to(0) if $self->value_next_page;
}

has id => (
    is      => 'rw',
    lazy    => 1,
    trigger => sub { $_[0]->blank(defined $_[1] ? 0 : 1) },
    builder => sub { $_[0]->value_hash && $_[0]->value_hash->{id} },
);

sub ids { [ $_[0]->id ] }

sub _build_blank { $_[0]->id ? 0 : 1 }

has has_id => (
    is  => 'rw',
    isa => Bool,
);

sub value { $_[0]->id }

has value_hash => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->has_init_value or return;
        my $value = $self->init_value->[0]->{value};
        my $id = $value->{id};
        $self->has_id(1) if defined $id || $self->init_no_value;
        +{
            id       => $id,
            name     => $value->{name},
            mimetype => $value->{mimetype},
        };
    },
);

# Make up for missing predicated value property
sub has_value { $_[0]->has_id }

has name => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->value_hash ? $_[0]->value_hash->{name} : $_[0]->_rset && $_[0]->_rset->name;
    },
);

has mimetype => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->value_hash ? $_[0]->value_hash->{mimetype} : $_[0]->_rset && $_[0]->_rset->mimetype;
    },
);

# Needed in case this is unattached file, in which case schema
# is not in column property
has schema => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->column->schema;
    },
);

has _rset => (
    is => 'lazy',
);

sub _build__rset
{   my $self = shift;
    $self->id or return;
    $self->column->user_can('read') or error __x"You do not have access to file ID {id}", id => $self->id
        if $self->column;
    $self->schema->resultset('Fileval')->find($self->id);
}

has content => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->_rset && $_[0]->_rset->content;
    },
);

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self,
        id       => $self->id,
        name     => $self->name,
        mimetype => $self->mimetype,
        content  => $self->content
    );
};


sub as_string
{   my $self = shift;
    $self->name // "";
}

sub as_integer
{   my $self = shift;
    $self->id // 0;
}

sub html
{   my $self = shift;
    return "" unless $self->id;
    my $id = $self->id;
    my $name = $self->name || "";
    return qq(<a href="/file/$id">$name</a>);
}

1;

