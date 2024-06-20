
=pod
GADS - Globally Accessible Data Store
Copyright (C) 2019 Ctrl O Ltd

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

package GADS::Datum::Filval;

use Log::Report;
use Moo;

extends 'GADS::Datum::Curval';

sub value_regex_test
{   my ($self, %options) = @_;

    # This may be called during record write, in which case we need to
    # re-evaluate the list of values, or it may be called during standard
    # record viewing, in which case we don't (and submission_token will not be
    # set)
    $self->re_evaluate(submission_token => $options{submission_token})
        if $options{submission_token};
    $self->text_all;
}

sub re_evaluate
{   my ($self, %options) = @_;

    my $related_field = $self->column->related_field;
    my $related_datum = $self->record->fields->{ $related_field->id };

    # Only re-evaluate the stored list of filtered values if something
    # significant has changed (the values that the filtered curval depends on,
    # or the curval itself). This is so that a simple unrelated change in a
    # record does not reproduce a different set of stored filtered values
    my $something_changed =
        $self->record->fields->{ $related_field->id }->changed;
    foreach my $col (@{ $related_field->subvals_input_required })
    {
        $something_changed = 1
            if $self->record->fields->{ $col->id }->changed;
    }

    return if !$something_changed && !$options{new_entry};

    my $submission_token = $options{submission_token}
        or panic "Missing submission token";
    my $submission_id =
        $self->column->schema->resultset('Submission')->search({
            token => $submission_token,
        })->next->id;

    my @ids = $self->column->schema->resultset('FilteredValue')->search({
        submission_id => $submission_id,
        layout_id     => $self->column->id,
    })->get_column('current_id')->all;

    if (!@ids)  # filtered_values() hasn't been called yet and the values stored
    {
        my $records =
            $self->column->related_field->filtered_values($submission_token);
        @ids = map $_->{id}, @$records;
    }

    $self->set_value(\@ids);
}

sub write_value
{   my ($self, %options) = @_;

    my @entries;

    foreach my $id (@{ $self->ids })
    {
        push @entries,
            {
                layout_id => $self->column->id,
                record_id => $self->record_id,
                value     => $id,
            };
    }
    if (!@entries)
    {
        # No values, but still need to write null value
        push @entries,
            {
                layout_id => $self->column->id,
                record_id => $self->record_id,
                value     => undef,
            };
    }
    $self->column->schema->resultset('Curval')->create($_) foreach @entries;

    $self->column->schema->resultset('FilteredValue')->search({
        layout_id     => $self->column->id,
        submission_id => $options{submission_id},
    })->delete;
}

1;
