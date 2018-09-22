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
    my ($self, $value) = @_;
    my $clone = $self->clone; # Copy before changing text
    my @values = sort grep {$_} ref $value eq 'ARRAY' ? @$value : ($value);
    my @old     = sort @{$self->ids};
    my $changed = "@values" ne "@old";
    if ($changed)
    {
        $self->changed(1);
        # Values can be submitted as either a database current ID, or as a
        # query string for new values
        my (@queries, @ids);
        foreach my $value (@values)
        {
            if ($value =~ /^[0-9]+$/)
            {
                $self->column->validate($value, fatal => 1);
                push @ids, $value;
            }
            else {
                push @queries, $value;
            }
        }
        $self->_set_values_as_query(\@queries);
        $self->_set_ids(\@ids);
        # Need to clear initial values, to ensure new value is built from this new ID
        $self->_clear_text_all;
        $self->_clear_text_hash;
        $self->clear_text;
        $self->clear_init_value;
        $self->_clear_init_value_hash;
        $self->_clear_records;
        $self->clear_blank;
    }
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
        +{
            records => \@records,
            ids     => \@ids,
        };
    }
    elsif ($self->column->type eq 'autocur') # Would be nice to abstract to autocur class
    {
        my @values = $self->column->fetch_multivalues([$self->record->record_id]);
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

has _records => (
    is      => 'lazy',
    isa     => Maybe[ArrayRef],
    clearer => 1,
);

sub _build__records
{   my $self = shift;
    $self->_init_value_hash->{records};
}

sub _build_blank
{   my $self = shift;
    @{$self->ids} || @{$self->values_as_query} ? 0 : 1;
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
    join '; ', map { $_->{value} } @{$self->_text_all};
}

# Internal text, array ref of all individual text values
has _text_all => (
    is        => 'rw',
    isa       => ArrayRef,
    lazy      => 1,
    clearer   => 1,
    predicate => 1,
    builder   => sub {
        my $self = shift;
        if ($self->_records)
        {
            return [ map { $self->column->_format_row($_) } @{$self->_records} ];
        }
        else {
            return $self->column->ids_to_values($self->ids, fatal => 1);
        }
    }
);

has _text_hash => (
    is      => 'lazy',
    isa     => HashRef,
    clearer => 1,
);

sub _build__text_hash
{   my $self = shift;
    +{
        map { $_->{id} => $_->{value} } @{$self->_text_all}
    };
}

has id_hash => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_id_hash
{   my $self = shift;
    +{ map { $_ => 1 } @{$self->ids} };
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
    $_->delete_current, $_->purge_current foreach grep { $_->is_draft } @{$self->_records};
}

# Values as a URI query string. These are values submitted as queries via the
# curval-edit functionality. They will either be existing records edited or new
# records
has values_as_query => (
    is      => 'rwp',
    isa     => ArrayRef,
    lazy    => 1,
    builder => sub {
        my $self = shift;
        return [] if !$self->_records;
        [ map { $_->as_query } grep { $_->is_draft } @{$self->_records} ];
    },
);

# The above values as queries, converted to records
has values_as_query_records => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_values_as_query_records
{   my $self = shift;
    my @records;
    foreach my $query (@{$self->values_as_query})
    {
        my $params = parse_query_string($query);
        grep { $_ !~ /^(current_id|field[0-9]+)$/ } keys %$params
            and error __x"Invalid query string: {query}", query => $query;
        my $record = GADS::Record->new(
            user     => $self->column->layout->user,
            layout   => $self->column->layout_parent,
            schema   => $self->column->schema,
            base_url => $self->column->base_url,
        );
        if (my $current_id = $params->{current_id})
        {
            $record->find_current_id($current_id, include_draft => 1);
        }
        else {
            $record->initialise;
        }
        foreach my $col ($self->column->layout_parent->all(user_can_write_new => 1))
        {
            my $newv = $params->{$col->field};
            $record->fields->{$col->id}->set_value($newv)
                if defined $params->{$col->field} && $col->userinput && defined $newv;
        }
        $record->set_blank_dependents; # XXX Move to write() once back/forward functionality rewritten?
        push @records, $record;
    }
    \@records;
}

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    # Only pass text in if it's already been built
    my %params = (
        ids => $self->ids,
    );
    $params{_text_all}  = $self->_text_all if $self->_has_text_all;
    $params{init_value} = $self->init_value if $self->has_init_value;
    $orig->($self, %params, @_);
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
    foreach my $v (@{$self->_text_all})
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
        ? $self->column->field_values(rows => $self->_records)
        : $self->column->field_values(ids => $self->ids);
    # Translate into something useful
    my @recs;
    push @recs, $values->{$_}
        foreach keys %$values;
    \@recs;
}

sub field_values_for_code
{   my $self = shift;
    $self->_records
        ? $self->column->field_values_for_code(rows => $self->_records)
        : $self->column->field_values_for_code(ids => $self->ids);
}

sub set_values
{   my $self = shift;
    [ map { $_->{id} } @{$self->html_form} ];
}

sub html_form
{   my $self = shift;
    my $values = $self->for_code;
    my $return = !defined $values
        ? []
        : ref $values eq 'ARRAY'
        ? $values
        : [$values];
    my @records = @{$self->values_as_query_records};
    foreach my $query (@{$self->values_as_query})
    {
        my $record = shift @records;
        # New entries may have a current ID from a failed database write, but
        # don't use
        my $id = $record->new_entry ? undef : $record->current_id;
        push @$return, +{
            id       => $id,
            as_query => $query,
            value    => $self->column->_format_row($record)->{mainvalue},
        };
    }
    return $return;
}

sub for_code
{   my ($self, %options) = @_;

    # Get all field data in one chunk
    my $field_values = $self->field_values_for_code;

    my @values = map {
        +{
            id           => int $_, # Ensure passed to Lua as number not string
            value        => $self->_text_hash->{$_},
            field_values => $field_values->{$_},
        }
    } (@{$self->ids});

    $self->column->multivalue ? \@values : $values[0];
}

1;
