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

use Log::Report;
use Moo;
use namespace::clean;

extends 'GADS::Datum';

has set_value => (
    is       => 'rw',
    trigger  => sub {
        my ($self, $value) = @_;
        my $first_time = 1 unless $self->has_id;
        my $new_id;
        $value = $value->{value} if ref $value && ref $value->{value};
        if (ref $value && $value->{content})
        {
            # New file uploaded
            $new_id = $self->schema->resultset('Fileval')->create({
                name     => $value->{name},
                mimetype => $value->{mimetype},
                content  => $value->{content},
            })->id;
            $self->name($value->{name});
            $self->mimetype($value->{mimetype});
        }
        elsif(ref $value) {
            $new_id = $value->{id};
            $self->name($value->{name});
            $self->mimetype($value->{mimetype});
        }
        else {
            # Just ID for file passed. Probably a resubmission
            # of a form with previous errors
            $new_id = $value;
        }
        unless ($first_time)
        {
            # Previous value
            $self->changed(1) if (!defined($self->id) && defined $value)
                || (!defined($value) && defined $self->id)
                || (defined $self->id && defined $value && $self->id != $value);
            $self->oldvalue($self->clone);
        }
        $self->id($new_id) if $new_id || $self->init_no_value;
    },
);

has id => (
    is        => 'rw',
    predicate => 1,
    trigger   => sub { $_[0]->blank(defined $_[1] ? 0 : 1) },
);

sub value { $_[0]->id }

# Make up for missing predicated value property
sub has_value { $_[0]->has_id }

has name => (
    is => 'rw',
);

has mimetype => (
    is => 'rw',
);

has schema => (
    is => 'rw',
);

has content => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->schema->resultset('Fileval')->find($self->id)->content;
    },
);

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self, id => $self->id, name => $self->name, mimetype => $self->mimetype);
};


# Not designed to be used within object. Just send file from ID.
# XXX Make OO?
sub get_file
{   my ($self, $id, $schema, $user) = @_;
    $id or error __"No ID provided for file retrieval";
    my $fileval = $schema->resultset('Fileval')->find($id)
        or error __x"File ID {id} cannot be found", id => $id;
    # Check whether this is hidden and whether the user has access
    my ($file) = $fileval->files; # In theory can be more than one, but not in practice (yet)
    # if ($file && $file->layout->hidden) # Could be unattached document
    # XXX Need to check if user has view access
    if ($file) # Could be unattached document
    {
        error __"You do not have access to this document"
            unless $user->{permission}->{layout};
    }
    $fileval;
}

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

