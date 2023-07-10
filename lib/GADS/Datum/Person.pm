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

    $value = [$value] if ref $value ne 'ARRAY'; # Allow legacy single values as scalar
    $value ||= [];
    my @values = sort grep $_, @$value; # Take a copy first
    my $clone = $self->clone;
    my @old = sort @{$self->ids};

    my @values2;
    foreach my $value (@values)
    {
        my $id;
        if (ref $value)
        {
            # Used in tests to create user at same time.
            if ($value->{email})
            {
                $id = $self->schema->resultset('User')->find_or_create($value)->id;
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
                $id = $p->id if $p;
            }
            else {
                $id = $value;
            }
            !$id || $options{no_validation} || (grep {$value == $_->id} @{$self->column->people}) || $self->has_id($value) # Unchanged deleted user
                or error __x"'{int}' is not a valid person ID"
                    , int => $id;
            push @values2, $id;
            # Look up text value
        }
    }

    my $changed = (@values2 || @old) && (@values2 != @old || "@values2" ne "@old");
    if ($changed)
    {
        $self->changed(1);
        $self->_set_ids(\@values2);
        $self->clear_value_hash;
        $self->clear_init_value;
    }
    $self->oldvalue($clone);
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
    is      => 'rwp',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        # May or may not be multiple values, depending on source. Could have
        # come from a record value (multiple possible) or from a record
        # property such as created_by
        my $values;
        if ($self->has_init_value)
        {
            my $init_value = $self->init_value;
            $values = ref $init_value eq 'ARRAY'
                ? $init_value
                : [$init_value];
        }
        else {
            $values = $self->ids;
        }
        my @transformed;
        foreach my $value (@$values)
        {
            if (ref $value eq 'HASH')
            {
                # XXX - messy to account for different initial values. Can be tidied once
                # we are no longer pre-fetching multiple records
                $value = $value->{value} if exists $value->{record_id};
                # If only the value has been retrieved for the database query
                # (rather than the joined user as well) then retrieve the full
                # value
                ref $value eq 'HASH'
                    or $value = $self->column->id_to_hash($value);
                my $id = $value->{id};
                push @transformed, +{
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
                push @transformed, $self->column->id_to_hash($value);
            }
        }
        return \@transformed;
    },
);

# Whether to allow deleted users to be set
has allow_deleted => (
    is => 'rw',
);

sub search_values_unique
{   [shift->text];
}

has text_all => (
    is      => 'rwp',
    isa     => ArrayRef,
    lazy    => 1,
    builder => sub {
        my $self = shift;
        # By default we return empty strings. These make their way to grouped
        # display as the value to filter for, so this ensures that something
        # like "undef" doesn't display
        [ sort map { defined $_->{value} ? $_->{value} : '' } @{$self->value_hash} ];
    },
);

sub has_id
{   my ($self, $id) = @_;
    !! grep $id == $_, @{$self->ids};
}

has ids => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        [map $_->{id}, @{$self->value_hash}];
    }
);

sub html_form
{   my $self = shift;
    $self->ids;
}

sub _build_blank { @{$_[0]->ids} ? 0 : 1 }

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
        emails  => [$_->{email}],
        text    => $text,
        html    => $html,
    }) foreach @{$self->value_hash};
}

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self,
        value_hash => [
            map {
                +{
                    id            => $_->{id},
                    email         => $_->{email},
                    username      => $_->{username},
                    firstname     => $_->{firstname},
                    surname       => $_->{surname},
                    freetext1     => $_->{freetext1},
                    freetext2     => $_->{freetext2},
                    organisation  => $_->{organisation},
                    department    => $_->{department},
                    department_id => $_->{department_id},
                    team          => $_->{team},
                    team_id       => $_->{team_id},
                    title         => $_->{title},
                    value         => $_->{value},
                },
            } @{$self->value_hash}
        ],
        schema => $self->schema,
        @_,
    );
};

sub for_table
{   my $self = shift;

    my @vals;

    if (!$self->blank)
    {
        foreach my $v (@{$self->value_hash})
        {
            my $val = {
                text => $v->{value},
            };
            my $site = $self->column->layout->site;
            my @details;
            if (my $email = $v->{email})
            {
                push @details, {
                    value => $v->{email},
                    type  => 'email'
                };
            }

            for (
                [$v->{freetext1}, $site->register_freetext1_name],
                [$v->{freetext2}, $site->register_freetext2_name]
            ) {
                next unless $_->[0];

                push @details, {
                    definition => $_->[1],
                    value      => $_->[0],
                    type       => 'text'
                };
            }
            $val->{details} = \@details;
            push @vals, $val;
        }
    }

    my $return = $self->for_table_template;
    $return->{values} = \@vals;
    $return;
}

sub as_string
{   my $self = shift;
    join ', ', @{$self->text_all};
}

sub as_integer { panic "Not implemented" }

sub _build_for_code
{   my $self = shift;

    my @values = map {
        +{
            id           => $self->{id},
            surname      => $self->{surname},
            firstname    => $self->{firstname},
            email        => $self->{email},
            freetext1    => $self->{freetext1},
            freetext2    => $self->{freetext2},
            organisation => $self->{organisation},
            department   => $self->{department},
            team         => $self->{team},
            title        => $self->{title},
            text         => $self->{value},
        }
    } @{$self->value_hash};

    $self->column->multivalue || @values > 1 ? \@values : $values[0];
}

1;

