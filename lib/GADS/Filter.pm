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
use JSON qw(decode_json encode_json);
use Log::Report;
use MIME::Base64;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has as_json => (
    is      => 'rw',
    isa     => sub {
        decode_json($_[0]); # Will die on error
    },
    lazy    => 1,
    clearer => 1,
    coerce  => sub {
        # Ensure consistent format
        encode_json(decode_json($_[0]));
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
        $self->_set_changed(1) if $self->has_value && !Compare($self->as_hash, decode_json($new));
        $self->clear_as_hash;
        $self->_clear_lazy;
        $self->_set_has_value(1);
    },
);

has as_hash => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        $self->_set_has_value(1);
        return {} if !$self->has_as_json;
        decode_json($self->as_json);
    },
    trigger => sub {
        my ($self, $new) = @_;
        $self->_set_changed(1) if $self->has_value && !Compare(decode_json($self->as_json), $new);
        $self->clear_as_json;
        $self->_clear_lazy;
        $self->_set_has_value(1);
    },
);

has has_value => (
    is  => 'rwp',
    isa => Bool,
);

# Clear various lazy accessors that depend on the above values
sub _clear_lazy
{   my $self = shift;
    $self->clear_filters;
    $self->clear_column_ids;
}

sub base64
{   my $self = shift;
    encode_base64($self->as_json);
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
    [ map { $_->{field} } @{$self->filters} ];
}

# All the filters in a flat structure
has filters => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

sub _build_filters
{   my $self = shift;
    my $cols_in_filter = {};
    _filter_tables($self->as_hash, $cols_in_filter);
    [values %$cols_in_filter];
}

# Recursively find all tables in a nested filter
sub _filter_tables
{   my ($filter, $tables) = @_;

    if (my $rules = $filter->{rules})
    {
        # Filter has other nested filters
        foreach my $rule (@$rules)
        {
            _filter_tables($rule, $tables);
        }
    }
    elsif (my $id = $filter->{id}) {
        $tables->{$filter->{id}} = {
            field    => $filter->{id},
            value    => $filter->{value},
            operator => $filter->{operator},
        };
    }
}

# The IDs of the columns that will be subbed into the filter
sub columns_in_subs
{   my ($self, $layout) = @_;
    my @filters = grep { $_ } map { $_->{value} =~ /^\$([_0-9a-z]+)$/i; $1 } @{$self->filters};
    [ map { $layout->column_by_name_short($_) } @filters ];
}

# Sub into the filter values from a record
sub sub_values
{   my ($self, $record) = @_;
    my $filter = $self->as_hash;
    $self->_sub_filter_single($_, $record)
        foreach @{$filter->{rules}};
    $self->as_hash($filter);
    return;
}

sub _sub_filter_single
{   my ($self, $single, $record) = @_;
    if ($single->{rules})
    {
        $self->_sub_filter_single($_, $record)
            foreach @{$single->{rules}};
    }
    elsif ($single->{value} && $single->{value} =~ /^\$([_0-9a-z]+)$/i)
    {
        my $col = $record->layout->column_by_name_short($1)
            or return;
        my $datum = $record->fields->{$col->id};
        # First check for multivalue. If it is, we replace the singular rule
        # in this hash with a rule for each value and OR them all together
        if ($col->multivalue)
        {
            my @texts = @{$datum->text_all};
            if (@texts == 1)
            {
                $single->{value} = $texts[0];
            }
            else {
                my %template = %$single;
                %$single = (
                    condition => 'OR',
                    rules     => [],
                );
                foreach my $text (@texts)
                {
                    my %rule = %template;
                    $rule{value} = $text;
                    push @{$single->{rules}}, \%rule;
                }
            }
        }
        else {
            $datum->re_evaluate if !$col->userinput;
            $single->{value} = $datum->as_string;
        }
    }
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
