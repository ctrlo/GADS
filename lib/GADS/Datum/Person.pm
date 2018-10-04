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

package GADS::Datum::Person;

use DateTime;
use HTML::Entities;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;
use namespace::clean;

extends 'GADS::Datum';

with 'GADS::Role::Presentation::Datum::Person';

after set_value => sub {
    my ($self, $value, %options) = @_;
    ($value) = @$value if ref $value eq 'ARRAY';
    my $new_id;
    my $clone = $self->clone;
    if (ref $value)
    {
        # Used in tests to create user at same time.
        if ($value->{email})
        {
            $new_id = $self->schema->resultset('User')->find_or_create($value)->id;
            $self->column->clear_people;
        }
    }
    else {
        # User input.
        # First check if a textual value has been provided (e.g. import)
        if ($value && $value !~ /^[0-9]+$/)
        {
            # Swap surname/forename if no comma
            my $orig = $value;
            $value =~ s/(.*)\h+(.*)/$2, $1/ if $value !~ /,/;
            # Try and find in users
            (my $p) = grep {$value eq $_->value} @{$self->column->people};
            error __x"Invalid name '{name}'", name => $orig if !$p;
            $value = $p->id if $p;
        }
        !$value || $options{no_validation} || (grep {$value == $_->id} @{$self->column->people}) || $value == $self->id # Unchanged deleted user
            or error __x"'{int}' is not a valid person ID"
                , int => $value;
        $value = undef if !$value; # Can be empty string, generating warnings
        $new_id = $value;
        # Look up text value
    }
    if (
           (!defined($self->id) && defined $new_id)
        || (!defined($new_id) && defined $self->id)
        || (defined $self->id && defined $new_id && $self->id != $new_id)
    ) {
        my $person;
        $person = $self->schema->resultset('User')->find($new_id) if $new_id;
        foreach my $f (qw(firstname surname email freetext1 freetext2 id))
        {
            $self->$f($person ? $person->$f : undef);
        }
        if ($person)
        {
            my $org = _org_to_hash($person->organisation);
            $self->organisation($org);
            my $title = _org_to_hash($person->title);
            $self->title($title);
        }
        $self->_set_text($person ? $person->value : undef);
        $self->changed(1);
    }
    $self->oldvalue($clone);
    $self->id($new_id);
};

has schema => (
    is       => 'rw',
    required => 1,
);

sub _org_to_hash
{   my $org = shift;
    $org or return {};
    +{
        id   => $org->id,
        name => $org->name,
    };
}

has value_hash => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->has_init_value or return;
        # May or may not be multiple values, depending on source. Could have
        # come from a record value (multiple possible) or from a record
        # property such as created_by
        my $init_value = $self->init_value;
        my $value = ref $init_value eq 'ARRAY'
            ? $init_value->[0]
            : $init_value;
        # XXX - messy to account for different initial values. Can be tidied once
        # we are no longer pre-fetching multiple records
        $value = $value->{value} if exists $value->{record_id};
        my $id = $value->{id};
        $self->has_id(1) if defined $id || $self->init_no_value;
        +{
            id           => $id,
            email        => $value->{email},
            username     => $value->{username},
            firstname    => $value->{firstname},
            surname      => $value->{surname},
            freetext1    => $value->{freetext1},
            freetext2    => $value->{freetext2},
            organisation => $value->{organisation},
            title        => $value->{title},
            text         => $value->{value},
        };
    },
);

# Whether to allow deleted users to be set
has allow_deleted => (
    is => 'rw',
);

has _rset => (
    is => 'lazy',
);

sub _build__rset
{   my $self = shift;
    $self->id or return;
    $self->schema->resultset('User')->find($self->id);
}

has email => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->value_hash ? $_[0]->value_hash->{email} : $_[0]->_rset && $_[0]->_rset->email;
    },
);

has username => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->value_hash ? $_[0]->value_hash->{username} : $_[0]->_rset && $_[0]->_rset->username;
    },
);

has firstname => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->value_hash ? $_[0]->value_hash->{firstname} : $_[0]->_rset && $_[0]->_rset->firstname;
    },
);

has surname => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->value_hash ? $_[0]->value_hash->{surname} : $_[0]->_rset && $_[0]->_rset->surname;
    },
);

has freetext1 => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->value_hash ? $_[0]->value_hash->{freetext1} : $_[0]->_rset && $_[0]->_rset->freetext1;
    },
);

has freetext2 => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->value_hash ? $_[0]->value_hash->{freetext2} : $_[0]->_rset && $_[0]->_rset->freetext2;
    },
);

has organisation => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        # Do we have a resultset? If so, just return that
        return $self->_rset->organisation if $self->_rset;
        # Otherwise assume value_hash and build from that
        my $organisation_id = $self->value_hash && $self->value_hash->{organisation}
            or return undef;
        $self->schema->resultset('Organisation')->find($organisation_id);
    },
);

has title => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        # Do we have a resultset? If so, just return that
        return $self->_rset->title if $self->_rset;
        # Otherwise assume value_hash and build from that
        my $title_id = $self->value_hash && $self->value_hash->{title}
            or return undef;
        $self->schema->resultset('Title')->find($title_id);
    },
);

sub search_values_unique
{   [shift->text];
}

has text => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->value_hash ? $_[0]->value_hash->{text} : $_[0]->_rset && $_[0]->_rset->text;
    },
);

has id => (
    is      => 'rw',
    lazy    => 1,
    trigger => sub { $_[0]->blank(defined $_[1] ? 0 : 1) },
    builder => sub {
        $_[0]->value_hash && $_[0]->value_hash->{id}; # Don't try and build from rset, as that needs id set
    },
);

has has_id => (
    is  => 'rw',
    isa => Bool,
);

sub ids { [ $_[0]->id ] }

sub value { $_[0]->id }

sub _build_blank { $_[0]->id ? 0 : 1 }

# Make up for missing predicated value property
sub has_value { $_[0]->has_id }

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self,
        id           => $self->id,
        email        => $self->email,
        username     => $self->username,
        schema       => $self->schema,
        firstname    => $self->firstname,
        surname      => $self->surname,
        freetext1    => $self->freetext1,
        freetext2    => $self->freetext2,
        organisation => $self->organisation,
        title        => $self->title,
        text         => $self->text,
        @_,
    );
};

sub _set_text
{   my ($self, $value) = @_;

    # There used to be code here to update the cached value
    # if required. Now all removed to controller
    $self->text($value || "");
}

sub as_string
{   my $self = shift;
    $self->text // "";
}

sub as_integer
{   my $self = shift;
    $self->id // 0;
}

sub for_code
{   my $self = shift;
    +{
        surname      => $self->surname,
        firstname    => $self->firstname,
        email        => $self->email,
        freetext1    => $self->freetext1,
        freetext2    => $self->freetext2,
        organisation => $self->organisation,
        title        => $self->title,
        text         => $self->text,
    };
}

1;

