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
use GADS::User;
use Log::Report;
use Moo;
use namespace::clean;

use overload '""' => \&as_string;

extends 'GADS::Datum';

my @user_fields = qw(firstname surname email telephone id);

has set_value => (
    is       => 'rw',
    required => 1,
    trigger  => sub {
        my ($self, $value) = @_;
        my $first_time = 1 unless $self->has_id;
        my $new_id;
        if (ref $value)
        {
            # From database, with user table joined
            if ($value = $value->{value})
            {
                $new_id = $value->{id};
                foreach my $f (@user_fields)
                {
                    $self->$f($value->{$f});
                }
                $self->_set_text($value->{value});
            }
        }
        else {
            # User input
            !$value || grep {$value == $_->id} @{$self->column->people}
                or error __x"'{int}' is not a valid person ID"
                    , int => $value;
            $value = undef if !$value; # Can be empty string, generating warnings
            $new_id = $value;
            # Look up text value
        }
        unless ($first_time)
        {
            # Previous value. See if it's an update, in which case all fields
            # will need updating
            if (
                   (!defined($self->id) && defined $value)
                || (!defined($value) && defined $self->id)
                || (defined $self->id && defined $value && $self->id != $value)
            ) {
                # XXX Move to a better class?
                my $person;
                $person = $self->schema->resultset('User')->find($new_id) if $new_id;
                foreach my $f (@user_fields)
                {
                    $self->$f($person ? $person->$f : undef);
                }
                $self->_set_text($person ? $person->value : undef);
                $self->changed(1);
                $self->oldvalue($self->id);
            }
        }
        $self->id($new_id);
    },
);

has value => (
    is       => 'rw',
    lazy     => 1,
    builder  => sub {
        my $self = shift;
        $self->_transform_value($self->set_value);
    },
);

has schema => (
    is       => 'rw',
    required => 1,
);

# Whether to allow deleted users to be set
has allow_deleted => (
    is => 'rw',
);

has email => (
    is      => 'rw',
);

has firstname => (
    is      => 'rw',
);

has surname => (
    is      => 'rw',
);

has telephone => (
    is      => 'rw',
);

has text => (
    is      => 'rw',
);

has id => (
    is        => 'rw',
    predicate => 1,
    trigger   => sub { $_[0]->blank(defined $_[1] ? 0 : 1) },
);

sub _set_text
{   my ($self, $value) = @_;

    # There used to be code here to update the cached value
    # if required. Now all removed to controller
    $self->text($value);
}

sub html
{   my $self = shift;
    my @details;
    return unless $self->id;
    if (my $e = $self->email)
    {
        push @details, qq(Email: <a href='mailto:$e'>$e</a>);
    }
    if (my $t = $self->telephone)
    {
        push @details, qq(Telephone: $t);
    }
    my $details = join '<br>', @details;
    my $text = $self->text;
    return qq(<a style="cursor: pointer" class="personpop" data-toggle="popover"
        title="$text"
        data-content="$details">$text</a>
    );
}

sub as_string
{   my $self = shift;
    $self->text // "";
}

1;

