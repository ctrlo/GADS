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
use HTML::FromText qw(text2html);
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
        $self->changed(1);
        $self->id($new_id);
        $self->clear;
    }
    $self->oldvalue($clone);
};

sub clear
{   my $self = shift;
    $self->clear_email;
    $self->clear_username;
    $self->clear_firstname;
    $self->clear_surname;
    $self->clear_freetext1;
    $self->clear_freetext2;
    $self->clear_organisation;
    $self->clear_department;
    $self->clear_team;
    $self->clear_title;
    $self->clear_text;
}

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
    is      => 'rwp',
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
        if (ref $value eq 'HASH')
        {
            # XXX - messy to account for different initial values. Can be tidied once
            # we are no longer pre-fetching multiple records
            $value = $value->{value} if exists $value->{record_id};
            my $id = $value->{id};
            $self->has_id(1) if defined $id || $self->init_no_value;
            return +{
                id            => $id,
                email         => $value->{email},
                username      => $value->{username},
                firstname     => $value->{firstname},
                surname       => $value->{surname},
                freetext1     => $value->{freetext1},
                freetext2     => $value->{freetext2},
                organisation  => $value->{organisation},
                department    => $value->{department},
                department_id => $value->{department_id},
                team          => $value->{team},
                team_id       => $value->{team_id},
                title         => $value->{title},
                value         => $value->{value},
            };
        }
        elsif ($value) {
            return $self->column->id_to_hash($value);
        }
        else {
            return undef;
        }
    },
);

# Whether to allow deleted users to be set
has allow_deleted => (
    is => 'rw',
);

has email => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        $_[0]->value_hash && $_[0]->value_hash->{email};
    },
);

has username => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        $_[0]->value_hash && $_[0]->value_hash->{username};
    },
);

has firstname => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        $_[0]->value_hash && $_[0]->value_hash->{firstname};
    },
);

has surname => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        $_[0]->value_hash && $_[0]->value_hash->{surname};
    },
);

has freetext1 => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        $_[0]->value_hash && $_[0]->value_hash->{freetext1};
    },
);

has freetext2 => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        $_[0]->value_hash && $_[0]->value_hash->{freetext2};
    },
);

has organisation => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        # Organisation could be an ID, or a HASH with all details.
        # Whatever it is, convert to hash ref
        $self->value_hash && ref $self->value_hash->{organisation} eq 'HASH'
            ? $self->value_hash->{organisation}
            : $self->value_hash && $self->value_hash->{organisation}
            ? _org_to_hash($self->schema->resultset('Organisation')->find($self->value_hash->{organisation}))
            : undef;
    },
);

has department => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        # Department could be an ID, or a HASH with all details.
        # Whatever it is, convert to hash ref
        $self->value_hash && ref $self->value_hash->{department} eq 'HASH'
            ? $self->value_hash->{department}
            : $self->value_hash && $self->value_hash->{department_id}
            ? _org_to_hash($self->schema->resultset('Department')->find($self->value_hash->{department_id}))
            : undef;
    },
);

has team => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        # Team could be an ID, or a HASH with all details.
        # Whatever it is, convert to hash ref
        $self->value_hash && ref $self->value_hash->{team} eq 'HASH'
            ? $self->value_hash->{team}
            : $self->value_hash && $self->value_hash->{team_id}
            ? _org_to_hash($self->schema->resultset('Team')->find($self->value_hash->{team_id}))
            : undef;
    },
);

has title => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        # Title could be an ID, or a HASH with all details.
        # Whatever it is, convert to hash ref
        $self->value_hash && ref $self->value_hash->{title} eq 'HASH'
            ? $self->value_hash->{title}
            : $self->value_hash && $self->value_hash->{title_id}
            ? _org_to_hash($self->schema->resultset('Title')->find($self->value_hash->{title_id}))
            : undef;
    },
);

sub search_values_unique
{   [shift->text];
}

has text => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        $self->id or return;
        my $val = $self->value_hash && $self->value_hash->{value};
        $val ||= $self->schema->resultset('User')->find($self->id)->value;
        $val;
    },
);

has id => (
    is      => 'rw',
    lazy    => 1,
    trigger => sub {
        my ($self, $value) = @_;
        $self->clear;
        $self->_set_value_hash($self->column->id_to_hash($value));
        $self->blank(defined $value ? 0 : 1)
    },
    builder => sub {
        $_[0]->value_hash && $_[0]->value_hash->{id};
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

sub send_notify
{   my $self = shift;
    return if $self->blank || !$self->changed;
    my $email   = GADS::Email->instance;
    my $subject = $self->column->notify_on_selection_subject;
    my $text    = $self->column->notify_on_selection_message;
    my $replace = sub {
        my $var  = shift;
        my $name = $var =~ s/^\$//r;
        my $col  = $self->record->layout->column_by_name_short($name) or return $var;
        $self->record->fields->{$col->id}->as_string;
    };
    $subject =~ s/(\$[a-z0-9_]+)\b/$replace->($1)/ge;
    $text =~ s/(\$[a-z0-9_]+)\b/$replace->($1)/ge;
    my $html = text2html(
        $text,
        lines     => 1,
        urls      => 1,
        email     => 1,
        metachars => 1,
    );
    my $replace_links = sub {
        my ($name, $html) = @_;
        my $base = GADS::Config->instance->url;
        my $cid  = $self->record->current_id;
        my $link = "$base/record/$cid";
        return "<a href=\"$link\">$cid</a>" if $html;
        return $link;
    };
    $subject =~ s/(\$_link)\b/$replace_links->($1)/ge;
    $text =~ s/(\$_link)\b/$replace_links->($1)/ge;
    $html =~ s/(\$_link)\b/$replace_links->($1, 1)/ge;
    $email->send({
        subject => $subject,
        emails  => [$self->email],
        text    => $text,
        html    => $html,
    });
}

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
        department   => $self->department,
        team         => $self->team,
        title        => $self->title,
        text         => $self->text,
        @_,
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

sub _build_for_code
{   my $self = shift;
    +{
        id           => $self->id,
        surname      => $self->surname,
        firstname    => $self->firstname,
        email        => $self->email,
        freetext1    => $self->freetext1,
        freetext2    => $self->freetext2,
        organisation => $self->organisation,
        department   => $self->department,
        team         => $self->team,
        title        => $self->title,
        text         => $self->text,
    };
}

1;

