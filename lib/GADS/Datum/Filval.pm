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

after set_value => sub {
    my ($self, $value, %options) = @_;

    my $clone   = $self->clone; # Copy before changing text
    my @values  = sort grep {$_} ref $value eq 'ARRAY' ? @$value : ($value);
    my @records = grep { ref $_ eq 'GADS::Record' } @values;
    @values     = grep { ref $_ ne 'GADS::Record' } @values;
    my @ids     = grep { $_ =~ /^[0-9]+$/ } @values; # Submitted curval IDs of existing records
    my @queries = grep { $_ !~ /^[0-9]+$/ } @values; # New curval records or changes to existing ones
    my @old_ids = sort @{$self->ids};

    panic "Records cannot be mixed with other set values"
        if @records && (@ids || @queries);

    my $changed;
    $self->clear_values_as_records;

    if (@records)
    {
        $self->_set_values_as_records(\@records);
        @ids = map { $_->current_id } grep { !$_->new_entry } @records;
        # Exclude the parent curval to prevent recursive loops
        my @queries = map { $_->as_query(exclude_curcommon => 1) } grep { $_->new_entry } @records;
        $self->_set_values_as_query(\@queries);
        $self->clear_values_as_query_records; # Rebuild for new queries
    }

    if (@queries)
    {
        $self->_set_values_as_query(\@queries);
        $self->clear_values_as_query_records; # Rebuild for new queries
        $changed = 1 if grep { $_->is_edited } @{$self->values_as_query_records};
        # Remove any updated records from the list of old IDs in order to see
        # what has changed
        my %updated = map { $_->current_id => 1 } grep { !$_->new_entry } @{$self->values_as_query_records};
        @old_ids = grep { !$updated{$_} } @old_ids;
    }

    $changed ||= "@ids" ne "@old_ids"; #  Also see if IDs have changed

    if ($changed)
    {
        $self->changed(1);
        $self->column->validate($_, fatal => 1)
            foreach @ids;
        # Need to clear initial values, to ensure new value is built from this new ID
        $self->clear_values;
        $self->clear_text;
        $self->clear_init_value;
        $self->_clear_init_value_hash;
        $self->_clear_records;
        $self->clear_blank;
        $self->clear_already_seen_code;
        $self->clear_already_seen_level;
    }

    # Even if nothing has changed, we still need to set ids. This is because
    # the set values may have included unchanged records as queries. In this
    # case, the unchaged records will still be written as records
    # (values_as_query_records) even though they have not changed, so we don't
    # to also write the same IDs as values which will duplicate them.
    $self->_set_ids(\@ids);
    $self->oldvalue($clone);
};

sub re_evaluate
{   my ($self, %options) = @_;

    my $submission_token = $options{submission_token}
        or panic "Missing submission token";
    my $submission_id = $self->column->schema->resultset('Submission')->search({
        token => $submission_token,
    })->next->id;

    my @ids = $self->column->schema->resultset('FilteredValue')->search({
        submission_id => $submission_id,
        layout_id     => $self->column->id,
    })->get_column('current_id')->all;
    $self->set_value(\@ids);
}

sub write_value
{   my $self = shift;

    my @entries;

    foreach my $id (@{$self->ids})
    {
        push @entries, {
            layout_id => $self->column->id,
            record_id => $self->record_id,
            value     => $id,
        };
    }
    if (!@entries)
    {
        # No values, but still need to write null value
        push @entries, {
            layout_id => $self->column->id,
            record_id => $self->record_id,
            value     => undef,
        };
    }
    $self->column->schema->resultset('Curval')->create($_)
        foreach @entries;
}

1;
