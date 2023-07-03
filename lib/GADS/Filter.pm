=pod
GADS - Globally Accessible Data Store
Copyright (C) 2017 Ctrl O Ltd

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

package GADS::Filter;

use Data::Compare qw/Compare/;
use GADS::Config;
use Encode;
use JSON qw(decode_json encode_json);
use Log::Report 'linkspace';
use MIME::Base64;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has as_json => (
    is      => 'rw',
    isa     => sub {
        decode_json_utf8($_[0]); # Will die on error
    },
    lazy    => 1,
    clearer => 1,
    coerce  => sub {
        # Ensure consistent format
        my $json = shift || '{}';
        # Wrap in try block in case of invalid JSON, otherwise function will
        # bork uncleanly
        my $hash = try { decode_json_utf8($json) } || {};
        decode("utf8", encode_json($hash));
    },
    builder => sub {
        my $self = shift;
        $self->_set_has_value(1);
        encode_json($self->as_hash);
    },
    predicate => 1,
    trigger => sub {
        my ($self, $new) = @_;
        # Need to compare as structures, as stringified JSON could be in different orders
        $self->_set_changed(1) if $self->has_value && !Compare($self->as_hash, decode_json_utf8($new), { ignore_hash_keys => ['column_id'] });
        $self->clear_as_hash;
        # Force the hash to build with the new value, which will effectively
        # allow it to hold the old value, if we make any further changse (which
        # is then used to see if a change as happened)
        $self->as_hash;
        $self->_clear_lazy;
        $self->_set_has_value(1);
    },
);

has as_hash => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    clearer => 1,
    coerce  => sub {
        # Allow undef hash to initiate filter
        shift || {};
    },
    builder => sub {
        my $self = shift;
        $self->_set_has_value(1);
        return {} if !$self->has_as_json;
        decode_json_utf8($self->as_json);
    },
    trigger => sub {
        my ($self, $new) = @_;
        $self->_set_changed(1) if $self->has_value && !Compare(decode_json_utf8($self->as_json), $new, { ignore_hash_keys => ['column_id'] });
        $self->clear_as_json;
        # Force the JSON to build with the new value, which will effectively
        # allow it to hold the old value, if we make any further changse (which
        # is then used to see if a change as happened)
        $self->as_json;
        $self->_clear_lazy;
        $self->_set_has_value(1);
    },
);

has has_value => (
    is  => 'rwp',
    isa => Bool,
);

has layout => (
    is       => 'rw',
    # Make a weak ref so that when this object is created, it doesn't require
    # the reference to the layout to be destroyed to destroy this filter
    weak_ref => 1,
);

# Takes a JSON string that has wide characters, decodes it into utf8 bytes
# first, and then decodes the JSON. decode_json() expects utf8 binary
# characters, otherwise it borks. This module saves to the database and uses
# JSON as unicode, not utf8.
sub decode_json_utf8
{   decode_json(encode("utf8", shift)) }

# Clear various lazy accessors that depend on the above values
sub _clear_lazy
{   my $self = shift;
    $self->clear_filters;
    $self->clear_column_ids;
}

sub base64
{   my $self = shift;
    # First make sure we have the hash version
    $self->as_hash;
    # Then clear the JSON version so that we can rebuild it
    $self->clear_as_json;
    # Next update the filters
    foreach my $filter (@{$self->filters})
    {
        $self->layout or panic "layout has not been set in filter";
        my $col = $self->layout->column($filter->{column_id})
            or next; # Ignore invalid - possibly since deleted
        if ($col->has_filter_typeahead)
        {
            $filter->{data} = {
                text => $col->filter_value_to_text($filter->{value}),
            };
        }
        if ($col->type eq 'filval')
        {
            $filter->{filtered} = $col->related_field_id,
        }
    }
    # Now the JSON version will be built with the inserted data values
    encode_base64($self->as_json, ''); # Base64 plugin does not like new lines
}

has changed => (
    is => 'rwp',
    isa => Bool,
);

# The IDs of all the columns referred to by this filter
has column_ids => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

sub _build_column_ids
{   my $self = shift;
    [ map { $_->{id} } @{$self->filters} ];
}

# All the filters in a flat structure
has filters => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

sub _build_filters
{   my $self = shift;
    my $cols_in_filter = [];
    $self->_filter_tables($self->as_hash, $cols_in_filter);
    $cols_in_filter;
}

# Recursively find all tables in a nested filter
sub _filter_tables
{   my ($self, $filter, $tables) = @_;

    if (my $rules = $filter->{rules})
    {
        # Filter has other nested filters
        foreach my $rule (@$rules)
        {
            $self->_filter_tables($rule, $tables);
        }
    }
    elsif (my $id = $filter->{id}) {
        # XXX column_id should not really be stored in the hash, as it is
        # temporary but may be written out with the JSON later for permanent
        # use
        if ($id =~ s/^([0-9]+)_([0-9]+)$//)
        {
            $filter->{column_id} = $2;
        }
        else {
            $filter->{column_id} = $filter->{id};
        }
        # If we have a layout, remove any invalid columns
        if ($self->layout && !$self->layout->column($filter->{column_id}))
        {
            delete $filter->{$_} foreach keys %$filter;
        }
        push @$tables, $filter; # Keep as reference so can be updated by other functions
    }
}

# The IDs of the columns that will be subbed into the filter
has columns_in_subs => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_columns_in_subs
{   my $self = shift;
    my $layout = $self->layout
        or panic "layout has not been set in filter";
    my @filters = grep { $_ } map { $_->{value} && $_->{value} =~ /^\$([_0-9a-z]+)$/i && $1 } @{$self->filters};
    [ grep { $_ } map { $layout->column_by_name_short($_) } @filters ];
}

# Sub into the filter values from a record
sub sub_values
{   my ($self, $layout) = @_;
    my $filter = $self->as_hash;
    # columns_in_subs needs to be built now, otherwise it won't return the
    # correct result once the values have been subbed in below
    my $columns_in_subs = $self->columns_in_subs;
    if (!$layout->record && @$columns_in_subs)
    {
        # If we don't have a record (e.g. from typeahead search) and there
        # are known shortnames in the filter, then don't apply the filter
        # at all (there are no values to substitute in)
        $filter = {};
    }
    else {
        foreach (@{$filter->{rules}})
        {
            return 0 unless $self->_sub_filter_single($_, $layout);
        }
    }
    $self->as_hash($filter);
    return 1;
}

sub _sub_filter_single
{   my ($self, $single, $layout) = @_;
    my $record = $layout->record;
    if ($single->{rules})
    {
        foreach (@{$single->{rules}})
        {
            return 0 unless $self->_sub_filter_single($_, $layout);
        }
    }
    elsif ($single->{value} && $single->{value} =~ /^\$([_0-9a-z]+)$/i)
    {
        my $col = $layout->column_by_name_short($1);
        if (!$col)
        {
            trace "No match for short name $1";
            return 1; # Not a failure, just no match
        }
        my $datum = $record->fields->{$col->id};
        # First check for multivalue. If it is, we replace the singular rule
        # in this hash with a rule for each value and OR them all together
        if ($col->type eq 'curval')
        {
            # Can't really try and match on a text value
            $single->{value} = $datum->ids;
        }
        elsif ($col->multivalue)
        {
            $single->{value} = $datum->text_all;
        }
        else {
            $datum->re_evaluate if !$col->userinput;
            $single->{value} = $col->numeric ? $datum->values->[0] : $datum->as_string;
            trace __x"Value subbed into rule: {value} for column: {col}",
                value => $single->{value}, col => $col->name;
        }
    }
    return 1;
}

sub filter_types
{
    [
        { code => 'gt'      , text => 'Greater than' },
        { code => 'lt'      , text => 'Less than'    },
        { code => 'equal'   , text => 'Equals'       },
        { code => 'contains', text => 'Contains'     },
    ]
}

sub parse_date_filter
{   my ($class, $value) = @_;
    $value =~ /^(\h*([0-9]+)\h*([+])\h*)?CURDATE(\h*([-+])\h*([0-9]+)\h*)?$/
        or return;
    my $now = DateTime->now;
    my ($v1, $op1, $op2, $v2) = ($2, $3, $5, $6);
    if ($op1 && $op1 eq '+' && $v1)
    { $now->add(seconds => $v1) }
#    if ($op1 eq '-' && $v1) # Doesn't work, needs coding differently
#    { $now->subtract(seconds => $v1) }
    if ($op2 && $op2 eq '+' && $v2)
    { $now->add(seconds => $v2) }
    if ($op2 && $op2 eq '-' && $v2)
    { $now->subtract(seconds => $v2) }
    $now;
}

1;
