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

package GADS::Datum::Curcommon;

use CGI::Deurl::XS 'parse_query_string';
use HTML::Entities qw/encode_entities/;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Datum';

with 'GADS::Role::Presentation::Datum::Curcommon';

after set_value => sub {
    my ($self, $value, %options) = @_;

    # Ensure we don't accidentally set an autocur
    panic "Records passed to autocur set_value"
        if $self->column->type eq 'autocur' && !$options{allow_set_autocur};

    my $clone   = $self->clone; # Copy before changing text
    my @values  = sort grep {$_} ref $value eq 'ARRAY' ? @$value : ($value);
    my @records = grep { ref $_ eq 'GADS::Record' } @values;
    @values     = grep { ref $_ ne 'GADS::Record' } @values;
    my @ids     = grep { $_ =~ /^[0-9]+$/ } @values; # Submitted curval IDs of existing records
    my @queries = grep { $_ !~ /^[0-9]+$/ } @values; # New curval records or changes to existing ones
    my @old_ids = sort @{$self->all_ids};

    panic "Records cannot be mixed with other set values"
        if @records && (@ids || @queries);

    my $changed;
    $self->clear_values_as_records;

    if (@records)
    {
        $self->_set_values_as_records(\@records);
        @ids = map { $_->current_id } grep { !$_->new_entry } @records;
        # Exclude the parent curval to prevent recursive loops
        my @queries = map { $_->as_query(exclude_curcommon => $options{allow_set_autocur}) } grep { $_->new_entry } @records;
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

    # If the field is only showing limited records, then add on any existing
    # ones that won't have been shown
    if ($self->column->limit_rows && $self->column->multivalue)
    {
        my %submitted = map { $_ => 1 } @ids;
        push @ids, grep { !$submitted{$_} } @old_ids;
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
        $self->clear_all_ids;
    }

    # Even if nothing has changed, we still need to set ids. This is because
    # the set values may have included unchanged records as queries. In this
    # case, the unchaged records will still be written as records
    # (values_as_query_records) even though they have not changed, so we don't
    # to also write the same IDs as values which will duplicate them.
    $self->_set_ids(\@ids);
    $self->oldvalue($clone);
};

# Hash with various values built from init_value. Used to populate
# specific value properties
has _init_value_hash => (
    is      => 'lazy',
    isa     => HashRef,
    clearer => 1,
);

sub _build__init_value_hash
{   my $self = shift;
    if ($self->has_init_value) # May have been cleared after write
    {
        # initial value can either include whole record or just be ID. Assume
        # that they will be all one or the other
        my (@ids, @records);
        foreach my $v (@{$self->init_value})
        {
            my ($record, $id) = $self->_transform_value($v);
            push @records, $record if $record;
            # Don't include IDs of draft records. These will be recreated
            # afresh as required from the equivalent query string. Trying to
            # keep the same record from draft to main is too messy - things
            # like code values are not written, and removing the draft status
            # is fraught with danger.
            push @ids, $id if $id && (!$record || !$record->is_draft);
        }
        my $ret = {};
        $ret->{records} = \@records if @records;
        $ret->{ids}     = \@ids if @ids;
        return $ret;
    }
    elsif ($self->column->type eq 'autocur' && !$self->values_as_records) # Would be nice to abstract to autocur class
    {
        my $already_seen = {};
        my @values = $self->column->fetch_multivalues([$self->record->record_id], already_seen => $already_seen);
        @values = map { $_->{value} } @values;
        +{
            ids     => [ map { $_->current_id } @values ],
            records => \@values,
        };
    }
    else {
        +{};
    }
}

has values => (
    is        => 'lazy',
    isa       => ArrayRef,
    clearer   => 1,
    predicate => 1,
);

sub _build_values
{   my $self = shift;
    my @return;
    if ($self->_init_value_hash->{records})
    {
        @return = map { $self->column->_format_row($_) } @{$self->_init_value_hash->{records}};
    }
    elsif ($self->values_as_records)
    {
        foreach my $rec (@{$self->values_as_records})
        {
            my $values = $self->column->_format_row($rec)->{values};
            push @return, +{
                id       => !$rec->new_entry && $rec->current_id,
                as_query => $rec->new_entry && $rec->as_query,
                values   => $values,
                value    => $self->column->format_value(@$values),
                record   => $rec,
            };
        }
    }
    elsif (@{$self->ids} || @{$self->values_as_query}) {
        @return = $self->column->ids_to_values($self->ids, fatal => 1, rewind => $self->record->rewind);

        my @records = @{$self->values_as_query_records};
        foreach my $query (@{$self->values_as_query})
        {
            my $record = shift @records;
            my $values = $self->column->_format_row($record)->{values};
            push @return, +{
                id       => $record->current_id,
                as_query => $query,
                values   => $values,
                value    => $self->column->format_value(@$values),
                record   => $record,
            };
        }
    }
    return \@return;
}

sub text_all
{   my $self = shift;
    [ map { $_->{value} } @{$self->values} ];
}

has _records => (
    is      => 'lazy',
    isa     => Maybe[ArrayRef],
    clearer => 1,
);

sub _build__records
{   my $self = shift;
    return [ map { $_->{record} } @{$self->values} ];
}

sub _build_blank
{   my $self = shift;
    # Bulding values is expensive
    return @{$self->values} ? 0 : 1
        if $self->has_values;
    return 0 if @{$self->ids} || @{$self->values_as_query};
    # If this is part of a draft record, then there may be a draft curval edit
    # value. In that case, ids and values_as_query are empty, but the value is
    # in _init_value_hash
    return 0 if $self->_init_value_hash->{records} && @{$self->_init_value_hash->{records}};
    return 1;
}

has text => (
    is        => 'rwp',
    isa       => Str,
    lazy      => 1,
    builder   => 1,
    clearer   => 1,
    predicate => 1,
);

sub _build_text
{   my $self = shift;
    join '; ', map { $_->{value} } @{$self->values};
}

has id_hash => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_id_hash
{   my $self = shift;
    +{ map { $_->{record}->selector_id => 1 } @{$self->values} };
}

has ids => (
    is      => 'rwp',
    isa     => Maybe[ArrayRef],
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_init_value_hash->{ids} || [];
    },
);

# All the ids including any not shown through limit_rows
has all_ids => (
    is  => 'lazy',
    isa => ArrayRef,
    clearer => 1,
);

sub _build_all_ids
{   my $self = shift;
    return $self->ids if !$self->column->limit_rows;
    return [] if !$self->record || $self->record->new_entry;
    [$self->column->schema->resultset('Curval')->search({
        value     => { '!=' => undef },
        record_id => $self->record->record_id_old || $self->record->record_id,
        layout_id => $self->column->id,
    })->get_column('value')->all];
}

has ids_removed => (
    is  => 'lazy',
    isa => ArrayRef,
);

# The IDs of any records removed from this field's value
sub _build_ids_removed
{   my $self = shift;
    return [] if !$self->changed;
    my %old = map { $_ => 1 } @{$self->oldvalue->ids};
    delete $old{$_} foreach @{$self->ids};
    delete $old{$_->current_id} foreach grep { !$_->new_entry } @{$self->values_as_query_records};
    return [ keys %old ];
}

# IDs of any records that have been removed and automatically deleted. This is
# calculated and set when writing the record.
has ids_deleted => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

# All relevant ids (old and new)
has ids_affected => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_ids_affected
{   my $self = shift;
    my %ids = map { $_ => 1 } $self->oldvalue ?  @{$self->oldvalue->ids} : ();
    $ids{$_} = 1 foreach @{$self->ids};
    [ keys %ids ];
}

# ids that have been added or removed
has ids_changed => (
    is => 'lazy',
);

sub _build_ids_changed
{   my $self = shift;
    my %old_ids = map { $_ => 1 } $self->oldvalue ?  @{$self->oldvalue->ids} : ();
    my %new_ids = map { $_ => 1 } @{$self->ids};
    my %changed = map { $_ => 1 } @{$self->ids_affected};
    foreach (keys %changed)
    {
        delete $changed{$_} if $old_ids{$_} && $new_ids{$_};
    }
    [ keys %changed ];
}

sub id
{   my $self = shift;
    $self->column->multivalue
        and panic "Cannot return single id value for multivalue field";
    $self->ids->[0];
}

# Remove any draft subrecords that have been created just for this curval
# field. These will be removed when the main draft is removed.
sub purge_drafts
{   my $self = shift;
    # Do not use _records() if there are already records in the init_value.
    # This is faster, but also necessary, as all the values to build the full
    # _records() field may not have been retrieved.
    # XXX Ideally all the various properties containing records need tidying up
    # and unifying.
    my @records = $self->_init_value_hash->{records}
        ? @{$self->_init_value_hash->{records}}
        : @{$self->_records};
    $_->delete_current, $_->purge_current foreach grep { $_->is_draft } @records;
}

# Values as a URI query string. These are values submitted as queries via the
# curval-edit functionality. They will either be existing records edited or new
# records
has values_as_query => (
    is      => 'rwp',
    isa     => ArrayRef,
    default => sub { [] },
);

# The above values as queries, converted to records
has values_as_query_records => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

sub _build_values_as_query_records
{   my $self = shift;
    my @records;
    foreach my $query (@{$self->values_as_query})
    {
        my $params = parse_query_string($query);
        delete $params->{$_} foreach grep $_ =~ /_typeahead$/, keys %$params;
        grep { $_ !~ /^(?:csrf_token|current_id|field[0-9]+)$/ } keys %$params
            # Unlikely to be a user error
            and panic __x"Invalid query string: {query}", query => $query;
        my $record = GADS::Record->new(
            user   => $self->column->layout->user,
            layout => $self->column->layout_parent,
            schema => $self->column->schema,
        );
        if (my $current_id = $params->{current_id})
        {
            $record->find_current_id($current_id, include_draft => 1);
        }
        else {
            $record->initialise;
        }
        foreach my $col ($self->column->layout_parent->all(user_can_write_new => 1, userinput => 1))
        {
            my $newv = $params->{$col->field};
            # I can't find anything in official Jquery documentation, but
            # apparently form.serialize (the source of the query string)
            # encodes in utf-8. Therefore decode before passing into datums.
            my @newv = ref $newv eq 'ARRAY' ? @$newv : ($newv);
            $_ && utf8::decode($_) foreach @newv;
            $record->fields->{$col->id}->set_value(\@newv)
                if defined $params->{$col->field} && $col->userinput && defined $newv;
        }
        # Update any autocur fields with this record, so that the value can be
        # used immediately, without having to first write this record
        foreach my $col ($self->column->layout_parent->all)
        {
            next unless $col->type eq 'autocur';
            next unless $col->refers_to_instance_id == $self->record->layout->instance_id;
            my $datum = $record->fields->{$col->id};
            my @records = grep { $_->current_id != $self->record->current_id } map { $_->{record} } @{$datum->values};
            push @records, $self->record;
            $datum->set_value(\@records, allow_set_autocur => 1);
        }
        push @records, $record;
    }
    \@records;
}

has values_as_records => (
    is      => 'rwp',
    clearer => 1,
);

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    my %extra = @_;
    my $fresh = delete $extra{fresh}; # Whether to clone full fresh records
    my %params;
    # If this is a full record clone of a "noshow" curval field, then any
    # cloned values would be expected to be written as new independent records.
    # Therefore, for these, clone the records within the value
    if ($fresh && $self->column->value_selector eq 'noshow')
    {
        my @copied = map {
            $_->{record}->clone;
        } @{$self->values};
        $params{values_as_query} = [map { $_->as_query } @copied];
    }
    else {
        # ids is built when noshow is true
        $params{ids}        = $self->ids;
        $params{init_value} = $self->init_value if $self->has_init_value;
        $params{values}     = $self->values if $self->has_values;
    }
    $orig->($self, %params, %extra);
};

sub as_string
{   my $self = shift;
    $self->text // "";
}

sub as_integer
{   my $self = shift;
    $self->id // 0;
}

sub html_withlinks
{   my $self = shift;
    $self->as_string or return "";
    my @return;
    foreach my $v (@{$self->values})
    {
        my $string = encode_entities $v->{value};
        my $link = "/record/$v->{id}?oi=".$self->column->refers_to_instance_id;
        push @return, qq(<a href="$link">$string</a>);
    }
    join '; ', @return;
}

sub field_values
{   my $self = shift;
    my $values = $self->_records
        ? $self->column->field_values(rows => $self->_records, all_ids => $self->all_ids)
        : $self->column->field_values(ids => $self->ids, all_ids => $self->all_ids);
    # Translate into something useful
    my @recs;
    push @recs, $values->{$_}
        foreach keys %$values;
    delete $_->{record} foreach @recs;
    \@recs;
}

sub field_values_for_code
{   my ($self, %options) = @_;
    $self->_records
        ? $self->column->field_values_for_code(rows => $self->_records, all_ids => $self->all_ids, %options)
        : $self->column->field_values_for_code(ids => $self->ids, all_ids => $self->all_ids, %options);
}

sub set_values
{   my $self = shift;
    # Used for child records - need to always use ID for the child
    # value (instead of any queries), otherwise duplicate records created
    return $self->ids;
}

sub filter_value
{   my $self = shift;
    return $self->ids->[0];
}

sub html_form
{   my $self = shift;
    return $self->ids
        unless $self->column->show_add;
    my @return;
    foreach my $val (@{$self->values})
    {
        if ($val->{record}->is_draft)
        {
            $val->{as_query} = $val->{record}->as_query;
        }
        # New entries may have a current ID from a failed database write, but
        # don't use
        delete $val->{id} if $val->{record}->new_entry || $val->{record}->is_draft;
        $val->{presentation} = $val->{record}->presentation(curval_fields => $self->column->curval_fields);
        push @return, $val;
    }
    return \@return;
}

sub _build_for_code
{   my ($self, %options) = @_;

    # We need to clear values now, as it may have previously been built with
    # unwritten records (which do not have IDs and are therefore grepped out in
    # the code below). By the time we need this, the IDs should be available
    $self->clear_values;

    # Need to ensure that for code values we retrieve all the
    # values regardless, not restrained by the current user's permissions
    local $GADS::Schema::IGNORE_PERMISSIONS = 1;

    my $already_seen_code = $self->already_seen_code;
    # Get all field data in one chunk
    my $field_values = $self->field_values_for_code(
        already_seen_code => $already_seen_code,
        level             => $self->already_seen_level,
    );

    my @values = map {
        my $rec = delete $field_values->{$_}->{record};
        +{
            id           => int $_, # Ensure passed to Lua as number not string
            value        => $rec,
            field_values => $field_values->{$_},
        }
    } $self->changed ? (map $_->{id}, grep $_->{id}, @{$self->values}) : @{$self->all_ids};

    $self->column->multivalue || @values > 1 ? \@values : $values[0];
}

1;
