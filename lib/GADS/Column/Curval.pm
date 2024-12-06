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

with 'GADS::Role::Curcommon::CurvalMulti';

has '+option_names' => (
    default => sub { [qw/override_permissions value_selector show_add delete_not_used limit_rows show_view_all/] },
);

has show_view_all => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub {
        my $self = shift;
        return 0 unless $self->has_options;
        $self->options->{show_view_all};
    },
    trigger => sub { $_[0]->reset_options },
);

has value_selector => (
    is      => 'rw',
    isa     => sub { $_[0] =~ /^(typeahead|dropdown|noshow)$/ or panic "Invalid value_selector: $_[0]" },
    lazy    => 1,
    coerce => sub { $_[0] || 'dropdown' },
    builder => sub {
        my $self = shift;
        return 'dropdown' unless $self->has_options;
        exists $self->options->{value_selector} ? $self->options->{value_selector} : 'dropdown';
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
    is      => 'rw',
    clearer => 1,
);

has '+filter' => (
    builder => sub {
        my $self = shift;
        GADS::Filter->new(
            as_json => $self->set_filter || ($self->_rset && $self->_rset->filter),
            layout  => $self->layout_parent,
        )
    },
);

after clear => sub {
    my $self = shift;
    $self->clear_has_subvals;
    $self->clear_filter;
    $self->clear_set_filter;
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

    my %deps; # Used to track dependencies so that we can check recursive conditions
    my @cols = @{$self->filter->columns_in_subs};
    foreach my $col (@cols)
    {
        $deps{$self->id} ||= {};
        $deps{$self->id}->{$col->id} = 1;
        foreach my $cc (@{$col->depends_on})
        {
            $deps{$col->id} ||= {};
            $deps{$col->id}->{$cc} = 1;
            push @cols, $self->layout->column($cc);
        }
        foreach my $disp ($self->schema->resultset('DisplayField')->search({
            layout_id => $col->id
        })->all)
        {
            $deps{$col->id} ||= {};
            $deps{$col->id}->{$disp->display_field_id} = 1;
            push @cols, $self->layout->column($disp->display_field_id);
        }
    }

    # Check for recursive dependencies to prevent hanging in a loop
    foreach my $key (keys %deps)
    {
        my $ret = $self->layout->check_recursive(\%deps, $key);
        error __x"Unable to produce list of fields required for filtered field \"{field}\": calculated value or display condition recursive dependencies: {path}",
            field => $self->name, path => $ret if $ret;
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
    if (@{$self->curval_field_ids})
    {
        # Pick a random field from the selected display fields to work out the
        # parent layout
        my $random_id = $self->curval_field_ids->[0];
        my $random = $self->layout->column($random_id);
        return $random->instance_id if $random;
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

has filval_fields => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_filval_fields
{   my $self = shift;
    [
        map $self->layout->column($_), $self->schema->resultset('Layout')->search({
            type          => 'filval',
            related_field => $self->id,
        })->get_column('id')->all
    ]
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
