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

package GADS::Column::Curval;

use GADS::Config;
use GADS::Records;
use Log::Report 'linkspace';

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column::Curcommon';

has '+option_names' => (
    default => sub { [qw/override_permissions value_selector show_add delete_not_used/] },
);

has value_selector => (
    is      => 'rw',
    isa     => sub { $_[0] =~ /^(typeahead|dropdown|noshow)$/ or panic "Invalid value_selector: $_[0]" },
    lazy    => 1,
    coerce => sub { $_[0] || 'dropdown' },
    builder => sub {
        my $self = shift;
        my $default = $self->_rset && $self->_rset->typeahead ? 'typeahead' : 'dropdown';
        return $default unless $self->has_options;
        exists $self->options->{value_selector} ? $self->options->{value_selector} : $default;
    },
    trigger => sub { $_[0]->reset_options },
);

has show_add => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub {
        my $self = shift;
        return 0 unless $self->has_options;
        $self->options->{show_add};
    },
    trigger => sub {
        my ($self, $value) = @_;
        $self->multivalue(1) if $value && $self->value_selector eq 'noshow';
        $self->reset_options;
    },
);

has delete_not_used => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub {
        my $self = shift;
        return 0 unless $self->has_options;
        $self->options->{delete_not_used};
    },
    trigger => sub { $_[0]->reset_options },
);

has set_filter => (
    is => 'rw',
);

has '+filter' => (
    builder => sub {
        my $self = shift;
        GADS::Filter->new(
            as_json => $self->set_filter,
            layout  => $self->layout_parent,
        )
    },
);

after clear => sub {
    my $self = shift;
    $self->clear_has_subvals;
    $self->clear_subvals_input_required;
    $self->clear_data_filter_fields;
};

# Used to see whether we can filter yet using any filters defined for the
# curval field. If the filter contains values of the parent record, then that
# parent record needs to be set first
sub filter_view_is_ready
{   my $self = shift;
    return !!$self->view;
}

has view => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_view
{   my $self = shift;
    my $view = GADS::View->new(
        instance_id => $self->refers_to_instance_id,
        filter      => $self->filter,
        layout      => $self->layout_parent,
        schema      => $self->schema,
        user        => undef,
    );
    # Replace any "special" $short_name values with their actual value from the
    # record. If sub_values fails (due to record not being ready yet), then the
    # view is not built
    return unless $view->filter->sub_values($self->layout);
    return $view;
}

# Whether this field has subbed in values from other parts of the record in its
# filter
has has_subvals => (
    is      => 'lazy',
    isa     => Bool,
    clearer => 1,
);

sub _build_has_subvals
{   my $self = shift;
    !! @{$self->filter->columns_in_subs};
}

# The fields that we need input by the user for this filtered set of values
has subvals_input_required => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_subvals_input_required
{   my $self = shift;
    my @cols = @{$self->filter->columns_in_subs};
    foreach my $col (@cols)
    {
        push @cols, $self->layout->column($_)
            foreach @{$col->depends_on};
        foreach my $disp ($self->schema->resultset('DisplayField')->search({
            layout_id => $col->id
        })->all)
        {
            push @cols, $self->layout->column($disp->display_field_id)
        }
    }
    # Calc values do not need written to by user
    @cols = grep { $_->userinput } @cols;
    # Remove duplicates
    my %needed;
    $needed{$_->id} = $_ foreach @cols;
    @cols = values %needed;
    return \@cols;
}

# The string/array that will be used in the edit page to specify the array of
# fields in a curval filter
has data_filter_fields => (
    is      => 'lazy',
    isa     => Str,
    clearer => 1,
);

sub _build_data_filter_fields
{   my $self = shift;
    my @fields = @{$self->subvals_input_required};
    grep { $_->instance_id != $self->instance_id } @fields
        and warning "The filter refers to values of fields that are not in this table";
    '[' . (join ', ', map { '"'.$_->field.'"' } @fields) . ']';
}

sub _build_refers_to_instance_id
{   my $self = shift;
    my ($random) = $self->schema->resultset('CurvalField')->search({
        parent_id => $self->id,
    });
    return $random->child->instance->id if $random;
    if (@{$self->curval_field_ids})
    {
        # Maybe it hasn't been written yet, try again
        my $random_id = $self->curval_field_ids->[0];
        my $random = $self->schema->resultset('Layout')->find($random_id);
        return $random->instance->id if $random;
    }
    return undef;
}

sub make_join
{   my ($self, @joins) = @_;
    return $self->field
        if !@joins;
    +{
        $self->field => {
            value => {
                record_single => ['record_later', @joins],
            }
        }
    };
}

has autocurs => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_autocurs
{   my $self = shift;
    [
        $self->schema->resultset('Layout')->search({
            type          => 'autocur',
            related_field => $self->id,
        })->all
    ];
}

sub write_special
{   my ($self, %options) = @_;

    my $id   = $options{id};
    my $rset = $options{rset};

    unless ($options{override})
    {
        my $layout_parent = $self->layout_parent
            or error __"Please select a table to link to";
        $self->_update_curvals(%options);
    }

    # Update typeahead option
    $rset->update({
        typeahead   => 0, # No longer used, replaced with value_selector
    });

    # Clear what may be cached values that should be updated after write
    $self->clear;
    # Re-add the layout - will be missing as a result of the clear
    $self->filter->layout($self->layout);

    # Force any warnings to be shown about the chosen filter fields
    $self->data_filter_fields unless $options{override};

    return ();
};

sub validate
{   my ($self, $value, %options) = @_;
    return 1 if !$value;
    my $fatal = $options{fatal};
    if ($value !~ /^[0-9]+$/)
    {
        return 0 if !$fatal;
        error __x"Value for {column} must be an integer", column => $self->name;
    }
    if (!$self->schema->resultset('Current')->search({ instance_id => $self->refers_to_instance_id, id => $value })->next)
    {
        return 0 if !$fatal;
        error __x"{id} is not a valid record ID for {column}", id => $value, column => $self->name;
    }
    1;
}

sub fetch_multivalues
{   my ($self, $record_ids, %options) = @_;

    # Order by record_id so that all values for one record are grouped together
    # (enabling later code to work)
    my $m_rs = $self->schema->resultset('Curval')->search({
        'me.record_id'      => $record_ids,
        'me.layout_id'      => $self->id,
    },{
        order_by => 'me.record_id',
    });
    $m_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @values = $m_rs->all;
    my $records = GADS::Records->new(
        user                 => $self->override_permissions ? undef : $self->layout->user,
        layout               => $self->layout_parent,
        schema               => $self->schema,
        columns              => $self->curval_field_ids,
        limit_current_ids    => [map { $_->{value} } @values],
        is_draft             => $options{is_draft},
        columns              => $self->curval_field_ids_retrieve(all_fields => $self->retrieve_all_columns),
    );

    # We need to retain the order of retrieved records, so that they are shown
    # in the correct order within each field. This order is defined with the
    # default sort for each table
    my %retrieved; my $order;
    while (my $record = $records->single)
    {
        $retrieved{$record->current_id} = {
            record => $record,
            order  => ++$order, # store order
        };
    }

    my @return; my @single; my $last_record_id;
    foreach my $v (@values)
    {
        if ($last_record_id && $last_record_id != $v->{record_id})
        {
            @single = sort { $a->{order} && $b->{order} ? $a->{order} <=> $b->{order} : 0 } @single;
            push @return, @single;
            @single = ();
        }
        push @single, {
            layout_id => $self->id,
            record_id => $v->{record_id},
            value     => $v->{value} && $retrieved{$v->{value}}->{record},
            order     => $v->{value} && $retrieved{$v->{value}}->{order},
        };
        $last_record_id = $v->{record_id};
    };
    # Use previously stored order to sort records - records can be part of
    # multiple values
    @single = sort { $a->{order} && $b->{order} ? $a->{order} <=> $b->{order} : 0 } @single;
    push @return, @single;

    return @return;
}

sub multivalue_rs
{   my ($self, $record_ids) = @_;
    $self->schema->resultset('Curval')->search({
        'me.record_id'      => $record_ids,
        'me.layout_id'      => $self->id,
    });
}

sub random
{   my $self = shift;
    $self->all_ids->[rand @{$self->all_ids}];
}

sub import_value
{   my ($self, $value) = @_;

    $self->schema->resultset('Curval')->create({
        record_id    => $value->{record_id},
        layout_id    => $self->id,
        child_unique => $value->{child_unique},
        value        => $value->{value},
    });
}

1;
