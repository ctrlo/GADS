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

package GADS::Datum;

use HTML::Entities;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

with 'GADS::Role::Presentation::Datum';

use overload 'bool' => sub { 1 }, '""'  => 'as_string', '0+' => 'as_integer', fallback => 1;

has record => (
    is       => 'ro',
    weak_ref => 1,
);

has record_id => (
    is => 'rw',
);

has current_id => (
    is => 'rw',
);

has column => (
    is => 'rw',
);

has changed => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

has child_unique => (
    is      => 'rw',
    isa     => Bool,
    coerce  => sub { $_[0] ? 1 : 0 },
    default => 0,
    trigger => sub {
        my ($self, $value) = @_;
        $self->changed(1)
            if $self->_has_child_unique_old && $value != $self->_child_unique_old;
        $self->_child_unique_old($value);
    },
);

# Used to detect changes of child_unique
has _child_unique_old => (
    is        => 'rw',
    isa       => Bool,
    lazy      => 1,
    default   => 0,
    predicate => 1,
);

has blank => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    builder => 1,
    clearer => 1,
);

# Used to seed the value from the database
has init_value => (
    is        => 'ro',
    clearer   => 1,
    predicate => 1,
);

has init_no_value => (
    is  => 'rw',
    isa => Bool,
);

has oldvalue => (
    is      => 'rw',
    trigger => sub {
        my $self = shift;
        $self->clear_written_to;
    },
);

has has_value => (
    is => 'rw',
);

sub values
{   my $self = shift;
    panic "values() is now deprecated";
    my @values = ref $self->value eq 'ARRAY' ? @{$self->value} : ($self->value);
    # If a normal array is used (not array ref) then TT does not iterate over
    # the values properly if the only value is a "0"
    [@values];
}

# That value that will be used in an edit form to test the display of a
# display_field dependent field
sub value_regex_test
{   shift->as_string;
}

has written_to => (
    is      => 'rwp',
    isa     => Bool,
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        defined $self->oldvalue;
    },
);

# Whether this value is going to require approval. Used to know when to use the
# oldvalue as the correct current value
has is_awaiting_approval => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

sub ready_to_write
{   my $self = shift;
    if (my $col_id = $self->column->display_field)
    {
        return $self->record->fields->{$col_id}->ready_to_write;
    }
    return 1;
}

has show_for_write => (
    is      => 'rw',
    lazy    => 1,
    isa     => Bool,
    clearer => 1,
    builder => sub {
        my $self = shift;
        # If any field before this field is not being shown on this page (as
        # it's not ready yet), then also don't show this field. This forces
        # fields after those not-shown to display on the correct page.
        # The only exception is if the field depends on another field for
        # display - in that case, keep it with that field
        my $is_after_noshow = grep {
            # Don't include those on the previous page - will not be shown regardless
            !$self->record->fields->{$_->id}->value_previous_page
            # Anything already written to also won't be shown regardless
            # (only really applies in tests at the time of writing)
            && !$self->record->fields->{$_->id}->written_to
            # Only take fields before this one
            && $self->record->fields->{$_->id}->column->position < $self->column->position
            # And only ones the user can write, otherwise they will never be shown
            && $self->record->fields->{$_->id}->column->user_can('write')
            # Finally, it's not ready to write, so don't show this one
            && !$self->record->fields->{$_->id}->ready_to_write
        } $self->column->layout->all;

        return 0 if $is_after_noshow && !$self->column->display_field;

        if (my $col_id = $self->column->display_field)
        {
            return $self->record->fields->{$col_id}->show_for_write;
        }
        $self->ready_to_write && !$self->written_to;
    },
);

# This value was (or will be) shown on an edit page as a hidden value that
# contains a value from a previous page
has value_previous_page => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

# This value was (or will be) shown on the current edit page
has value_current_page => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

# This value was (or will be) shown on an edit page as a hidden value that
# contains a value from a future page, and which the user should be given
# another change to edit
has value_next_page => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

# Whether a value has been written to the datum that is valid (and not blank).
# Written values can include addable values.
has written_valid => (
    is      => 'rwp',
    isa     => Bool,
    default => 0,
);

sub text_all
{   my $self = shift;
    [$self->as_string];
}

sub html
{   my $self = shift;
    encode_entities $self->as_string;
}

sub html_form
{   my $self = shift;
    [ $self->value ];
}

# Overridden where applicable
sub html_withlinks { $_[0]->html }

# Not lazy, otherwise changes in display_field will not update this
sub dependent_not_shown
{   my $self = shift;
    my $display_field_id = $self->column->display_field
        or return;
    my $display_regex = $self->column->display_regex;
    $self->record->fields->{$display_field_id}->value_regex_test !~ /^$display_regex/;
}

sub clone
{   my ($self, @extra) = @_;
    # This will be called from a child class, in which case @extra can specify
    # additional attributes specific to that class
    ref($self)->new(
        record         => $self->record,
        column         => $self->column,
        record_id      => $self->record_id,
        current_id     => $self->current_id,
        blank          => $self->blank,
        ready_to_write => $self->ready_to_write,
        @extra
    );
}

sub for_code
{   my $self = shift;
    $self->as_string; # Default
}

sub _date_for_code
{   my ($self, $value) = @_;
    $value or return undef;
    +{
        year  => $value->year,
        month => $value->month,
        day   => $value->day,
        epoch => $value->epoch,
    };
}

1;

