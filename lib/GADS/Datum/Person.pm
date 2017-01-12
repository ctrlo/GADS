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
use Log::Report;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;
use namespace::clean;

extends 'GADS::Datum';

my @user_fields = qw(firstname surname email telephone id);

has set_value => (
    is       => 'rw',
    trigger  => sub {
        my ($self, $value) = @_;
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
            # User input
            !$value || (grep {$value == $_->id} @{$self->column->people}) || $value == $self->id # Unchanged deleted user
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
            foreach my $f (@user_fields)
            {
                $self->$f($person ? $person->$f : undef);
            }
            $self->_set_text($person ? $person->value : undef);
            $self->changed(1);
        }
        $self->oldvalue($clone);
        $self->id($new_id);
    },
);

has schema => (
    is       => 'rw',
    required => 1,
);

has value_hash => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->has_init_value or return;
        my $value = $self->init_value->{value};
        my $id = $value->{id};
        $self->has_id(1) if defined $id || $self->init_no_value;
        +{
            id        => $id,
            email     => $value->{email},
            firstname => $value->{firstname},
            surname   => $value->{surname},
            telephone => $value->{telephone},
            text      => $value->{value},
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

has telephone => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->value_hash ? $_[0]->value_hash->{telephone} : $_[0]->_rset && $_[0]->_rset->telephone;
    },
);

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

sub value { $_[0]->id }

# Make up for missing predicated value property
sub has_value { $_[0]->has_id }

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self,
        id        => $self->id,
        email     => $self->email,
        schema    => $self->schema,
        firstname => $self->firstname,
        surname   => $self->surname,
        telephone => $self->telephone,
        text      => $self->text,
    );
};

sub _set_text
{   my ($self, $value) = @_;

    # There used to be code here to update the cached value
    # if required. Now all removed to controller
    $self->text($value || "");
}

sub html
{   my $self = shift;
    my @details;
    return unless $self->id;
    if (my $e = $self->email)
    {
        $e = encode_entities $e;
        push @details, qq(Email: <a href='mailto:$e'>$e</a>);
    }
    if (my $t = $self->telephone)
    {
        $t = encode_entities $t;
        push @details, qq(Telephone: $t);
    }
    my $details = join '<br>', map {encode_entities $_} @details;
    my $text = encode_entities $self->text;
    return qq(<a style="cursor: pointer" class="personpop" data-toggle="popover"
        title="$text"
        data-content="$details">$text</a>
    );
}

sub as_string
{   my $self = shift;
    $self->text // "";
}

sub as_integer
{   my $self = shift;
    $self->id // 0;
}

1;

