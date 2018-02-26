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

package GADS::Layout;

use Algorithm::Dependency::Ordered;
use Algorithm::Dependency::Source::HoA;
use GADS::Column;
use GADS::Column::Autocur;
use GADS::Column::Calc;
use GADS::Column::Curval;
use GADS::Column::Date;
use GADS::Column::Daterange;
use GADS::Column::Enum;
use GADS::Column::File;
use GADS::Column::Intgr;
use GADS::Column::Person;
use GADS::Column::Rag;
use GADS::Column::String;
use GADS::Column::Tree;
use GADS::Instances;
use GADS::Graphs;
use GADS::MetricGroups;
use GADS::Views;
use Log::Report 'linkspace';
use MIME::Base64;
use String::CamelCase qw(camelize);

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

has schema => (
    is       => 'rw',
    required => 1,
);

has user => (
    is       => 'rw',
    required => 1,
);

has config => (
    is       => 'ro',
    required => 1,
);

has instance_id => (
    is  => 'rwp',
    isa => Int,
);

has _rset => (
    is      => 'lazy',
    clearer => 1,
);

sub _build__rset
{   my $self = shift;
    $self->schema->resultset('Instance')->find($self->instance_id);
}

has name => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    clearer => 1,
    builder => sub { $_[0]->_rset->name },
);

has site => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->site },
);

has homepage_text => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset->homepage_text },
);

has homepage_text2 => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset->homepage_text2 },
);

has forget_history => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => sub { $_[0]->_rset->forget_history },
    clearer => 1,
);

has sort_layout_id => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub { $_[0]->_rset->sort_layout_id },
);

has sort_type => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset->sort_type },
);

# Reference to the relevant record using this layout if applicable. Used for
# filtered curvals
has record => (
    is       => 'rw',
    weak_ref => 1,
);

has columns => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    builder => '_build_columns',
);

has _columns_namehash => (
    is      => 'lazy',
    isa     => HashRef,
    clearer => 1,
);

has _columns_name_shorthash => (
    is      => 'lazy',
    isa     => HashRef,
    clearer => 1,
);

has _user_permissions_columns => (
    is      => 'lazy',
    isa     => HashRef,
    clearer => 1,
);

sub _build__user_permissions_columns
{   my $self = shift;
    $self->user or return {};

    my $user_id  = $self->user->{id};

    +{
        $user_id => $self->_get_user_permissions($user_id),
    };
}

sub _get_user_permissions
{   my ($self, $user_id) = @_;
    my $perms_rs = $self->_user_perm_search('column', $user_id);
    $perms_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my ($user_perms) = $perms_rs->all; # The overall user. Only one due to query.
    my $return;
    if ($user_perms) # Might not be any at all
    {
        foreach my $group (@{$user_perms->{user_groups}}) # For each group the user has
        {
            foreach my $layout_group (@{$group->{group}->{layout_groups}}) # For each column in that group
            {
                # Push the actual permission onto an array
                $return->{$layout_group->{layout_id}}->{$layout_group->{permission}} = 1;
            }
        }
    }
    return $return;
}

has _user_permissions_table => (
    is      => 'lazy',
    isa     => HashRef,
    clearer => 1,
);

sub _build__user_permissions_table
{   my $self = shift;
    $self->user or return {};

    my $user_id  = $self->user->{id};
    my $perms_rs = $self->_user_perm_search('table', $user_id);
    my ($user_perms) = $perms_rs->all; # The overall user. Only one due to query.
    my $return = {};

    if ($user_perms) # Might not be any at all
    {
        foreach my $group ($user_perms->user_groups) # For each group the user has
        {
            foreach my $instance_group ($group->group->instance_groups) # For each column in that group
            {
                $return->{$instance_group->permission} = 1;
            }
        }
    }

    +{
        $user_id => $return,
    };
}

has _user_permissions_overall => (
    is      => 'lazy',
    isa     => HashRef,
    clearer => 1,
);

sub _build__user_permissions_overall
{   my $self = shift;
    $self->user or return {};
    my $user_id = $self->user->{id};
    my $overall = {};

    # First all the column permissions
    my $perms = $self->_user_permissions_columns->{$user_id};
    foreach my $col ($self->all)
    {
        $overall->{$_} = 1
            foreach keys %{$perms->{$col->id}};
    }

    # Then the table permissions
    $perms = $self->_user_permissions_table->{$user_id};
    $overall->{$_} = 1
        foreach keys %$perms;

    if ($self->user->{permission}->{superadmin})
    {
        $overall->{layout} = 1;
        $overall->{view_create} = 1;
    }

    return $overall;
}

sub current_user_can_column
{   my ($self, $column_id, $permission) = @_;
    my $user = $self->user
        or return;
    my $user_id  = $user->{id};
    return $self->user_can_column($user_id, $column_id, $permission);
}

sub user_can_column
{   my ($self, $user_id, $column_id, $permission) = @_;

    my $user_cache = $self->_user_permissions_columns->{$user_id};

    if (!$user_cache)
    {
        my $user_permissions = $self->_user_permissions_columns;
        $user_permissions->{$user_id} = $user_permissions->{$user_id} = $self->_get_user_permissions($user_id);
    }

    return $user_cache->{$column_id}->{$permission};
}

has _group_permissions => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build__group_permissions
{   my $self = shift;
    my @perms = $self->schema->resultset('InstanceGroup')->search({
        instance_id => $self->instance_id,
    })->all;
    my $return = {};
    foreach (@perms)
    {
        $return->{$_->group_id}->{$_->permission} = 1;
    }
    $return;
}

sub group_has
{   my ($self, $group_id, $permission) = @_;
    $self->_group_permissions->{$group_id} or return 0;
    $self->_group_permissions->{$group_id}->{$permission} or return 0;
}

has user_permission_override => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

has columns_index => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        my @columns = @{$self->columns};
        my %columns = map { $_->{id} => $_ } @columns;
        \%columns;
    },
);

has set_groups => (
    is        => 'rw',
    isa       => ArrayRef,
    predicate => 1,
);

sub write
{   my $self = shift;

    my $rset;
    if (!$self->instance_id)
    {
        $rset = $self->schema->resultset('Instance')->create({});
        $self->_set_instance_id($rset->id);
    }
    else {
        $rset = $self->_rset;
    }

    $rset->update({
        name => $self->name,
    });

    # Now set any groups if needed
    if ($self->has_set_groups)
    {
        my @create;
        my $delete = {};

        my %valid = (
            delete       => 1,
            purge        => 1,
            download     => 1,
            layout       => 1,
            message      => 1,
            view_create  => 1,
            create_child => 1,
            bulk_update  => 1,
            link         => 1,
        );

        my $existing = $self->_group_permissions;

        # Parse the form submimssion. Take the existing permissions: if exists, do
        # nothing, otherwise create
        foreach my $perm (@{$self->set_groups})
        {
            $perm =~ /^([0-9]+)\_(.*)/;
            my ($group_id, $permission) = ($1, $2);
            $group_id && $valid{$permission}
                or panic "Invalid permission $perm";
            # If it exists, delete from hash so we know what to delete
            delete $existing->{$group_id}->{$permission}
                or push @create, { instance_id => $self->instance_id, group_id => $group_id, permission => $permission };

        }
        # Create anything we need
        $self->schema->resultset('InstanceGroup')->populate([@create]);

        # Delete anything left - not in submission so therefore removed
        my @delete;
        foreach my $group_id (keys %$existing)
        {
            foreach my $permission (keys %{$existing->{$group_id}})
            {
                push @delete, {
                    instance_id => $self->instance_id,
                    group_id    => $group_id,
                    permission  => $permission,
                };
            }
        }
        $self->schema->resultset('InstanceGroup')->search([@delete])->delete
            if @delete;
    }
    $self->clear; # Rebuild all permissions etc
    $self; # Return self for chaining
}

sub delete
{   my $self = shift;
    $self->_rset->delete;
}

has internal_columns => (
    is      => 'ro',
    isa     => ArrayRef,
    builder => sub {
        [
            {
                id          => -11,
                name        => 'ID',
                type        => 'id',
                name_short  => '_id',
                table       => 'current',
                column      => 'id',
                isunique    => 1,
                return_type => 'integer',
            },
            {
                id          => -12,
                name        => 'Version Datetime',
                type        => 'date',
                name_short  => '_version_datetime',
                table       => 'record',
                column      => 'created',
                isunique    => 0,
                return_type => 'date',
            },
            {
                id          => -13,
                name        => 'Version User ID',
                type        => 'person',
                name_short  => '_version_user',
                table       => 'record',
                column      => 'createdby',
                isunique    => 0,
                return_type => 'integer',
            },
            {
                id          => -14,
                name        => 'Deleted by ID',
                type        => 'person',
                table       => 'current',
                column      => 'deletedby',
                isunique    => 0,
                hidden      => 1,
                return_type => 'integer',
            },
        ];
    },
);

sub clear_indexes
{   my $self = shift;
    $self->clear_name;
    $self->clear_columns_index;
    $self->_clear_columns_namehash;
    $self->_clear_columns_name_shorthash
}

sub clear
{   my $self = shift;
    $self->clear_columns;
    $self->clear_cols_db;
    $self->clear_indexes;
    $self->_clear_user_permissions_columns;
    $self->_clear_user_permissions_table;
    $self->_clear_user_permissions_overall;
    $self->clear_forget_history;
    $self->_clear_rset;
}

# The dump from the database of all the information needed to build the layout.
# Can be passed/shared for efficiency, as is common between layouts.
has cols_db => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_cols_db
{   my $self = shift;
    # Must search by instance_ids to limit between sites
    my @instance_ids = map { $_->id } $self->schema->resultset('Instance')->all;
    my $cols_rs = $self->schema->resultset('Layout')->search({
        'me.instance_id' => \@instance_ids,
    },{
        order_by => ['me.position', 'enumvals.id'],
        join     => 'enumvals',
        prefetch => ['calcs', 'rags', 'link_parent'],
    });
    $cols_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    [$cols_rs->all];
}

# Instantiate new class. This builds a list of all
# columns, so that it's cached for any later function
sub _build_columns
{   my $self = shift;

    my @return;
    foreach my $col (@{$self->cols_db})
    {
        my $class = "GADS::Column::".camelize $col->{type};
        my $column = $class->new(
            set_values               => $col,
            user_permission_override => $self->user_permission_override,
            instance_id              => $col->{instance_id},
            schema                   => $self->schema,
            layout                   => $self
        );
        push @return, $column;
    }

    # Now that we have everything built, we need to tag on dependent cols and permissions
    foreach my $col (@return)
    {
        # And also any columns that are children (in the layout)
        my @depends = grep {$_->display_field && $_->display_field == $col->id} @return;
        my @display_depended_by = map {
            {
                id        => $_->id,
                regex     => $_->display_regex,
                regex_b64 => encode_base64($_->display_regex),
            }
        } @depends;
        $col->display_depended_by(\@display_depended_by);
    }

    # Add on special internal columns
    foreach my $internal (@{$self->internal_columns})
    {
        my $class = $internal->{return_type} eq 'date'
            ? 'GADS::Column::Date'
            : 'integer'
            ? 'GADS::Column::Intgr'
            : 'GADS::Column';
        push @return, $class->new(
            id                       => $internal->{id},
            name                     => $internal->{name},
            name_short               => $internal->{name_short},
            isunique                 => $internal->{isunique},
            table                    => camelize($internal->{table}),
            sprefix                  => $internal->{table},
            value_field              => $internal->{column},
            type                     => $internal->{type},
            return_type              => $internal->{return_type},
            internal                 => 1,
            userinput                => 0,
            hidden                   => $internal->{hidden} || 0,
            user_permission_override => $self->user_permission_override,
            schema                   => $self->schema,
            layout                   => $self,
        );
    }

    \@return;
}

sub all_with_internal
{   my $self = shift;
    $self->all(@_, include_internal => 1);
}

sub columns_for_filter
{   my $self = shift;
    my @columns;
    my %restriction = (user_can_read => 1, include_internal => 1);
    foreach my $col ($self->all(%restriction))
    {
        push @columns, $col;
        if ($col->type eq 'curval')
        {
            foreach my $c ($col->layout_parent->all(%restriction))
            {
                $c->filter_id($col->id.'_'.$c->id);
                $c->filter_name($col->name.' ('.$c->name.')');
                push @columns, $c;
            }
        }
    }
    @columns;
}

sub all_user_read
{   my $self = shift;
    $self->all(user_can_read => 1);
}

sub all
{   my ($self, %options) = @_;

    my $type = $options{type};

    my @columns = grep { $_->instance_id == $self->instance_id && !$_->hidden } @{$self->columns};
    @columns = $self->_order_dependencies(@columns) if $options{order_dependencies};
    @columns = grep { !$_->internal } @columns unless $options{include_internal};
    @columns = grep { $_->internal } @columns if $options{only_internal};
    @columns = grep { $_->isunique } @columns if $options{only_unique};
    @columns = grep { $_->link_parent } @columns if $options{linked};
    @columns = grep { $_->type eq $type } @columns if $type;
    @columns = grep { $_->remember == $options{remember} } @columns if defined $options{remember};
    @columns = grep { $_->userinput == $options{userinput} } @columns if defined $options{userinput};
    @columns = grep { $_->multivalue == $options{multivalue} } @columns if defined $options{multivalue};
    @columns = grep { $_->user_can('read') } @columns if $options{user_can_read};
    @columns = grep { $_->user_can('write') } @columns if $options{user_can_write};
    @columns = grep { $_->user_can('write_new') } @columns if $options{user_can_write_new};
    @columns = grep { $_->user_can('write_existing') } @columns if $options{user_can_write_existing};
    @columns = grep { $_->user_can('write_existing') || $_->user_can('read') } @columns if $options{user_can_readwrite_existing};
    @columns = grep { $_->user_can('approve_new') } @columns if $options{user_can_approve_new};
    @columns = grep { $_->user_can('approve_existing') } @columns if $options{user_can_approve_existing};
    @columns;
}

# Order the columns in the order that the calculated values depend
# on other columns
sub _order_dependencies
{   my ($self, @columns) = @_;

    return unless @columns;

    my %deps = map {
        $_->id => $_->display_field ? [ $_->display_field ] : $_->depends_on,
    } @columns;

    my $source = Algorithm::Dependency::Source::HoA->new(\%deps);
    my $dep = Algorithm::Dependency::Ordered->new(source => $source)
        or die 'Failed to set up dependency algorithm';
    my @order = @{$dep->schedule_all};
    map { $self->columns_index->{$_} } @order;
}

sub position
{   my ($self, @position) = @_;
    my $count;
    foreach my $id (@position)
    {
        $count++;
        $self->schema->resultset('Layout')->find($id)->update({ position => $count });
    }
}

sub column
{   my ($self, $id, %options) = @_;
    $id or return;
    my $column = $self->columns_index->{$id}
        or return; # Column does not exist
    return if $options{permission} && !$column->user_can($options{permission});
    $column;
}

# Whether the supplied column ID is a valid one for this instance
sub column_this_instance
{   my ($self, $id) = @_;
    my $col = $self->columns_index->{$id}
        or return;
    $col->instance_id == $self->instance_id;
}

sub _build__columns_namehash
{   my $self = shift;
    my %columns = map { $_->name => $_ } @{$self->columns};
    \%columns;
}

sub column_by_name
{   my ($self, $name) = @_;
    $self->_columns_namehash->{$name};
}

sub _build__columns_name_shorthash
{   my $self = shift;
    my %columns = map { $_->name_short => $_ } grep { $_->name_short } @{$self->columns};
    \%columns;
}

sub column_by_name_short
{   my ($self, $name) = @_;
    $self->_columns_name_shorthash->{$name};
}

sub view
{   my ($self, $view_id, %options) = @_;

    return unless $view_id;
    my $view    = GADS::View->new(
        user        => $self->user,
        id          => $view_id,
        schema      => $self->schema,
        layout      => $self,
        instance_id => $self->instance_id,
    );
    my @columns_extra = $options{columns_extra} ? @{$options{columns_extra}} : ();
    my %view_layouts = map { $_ => 1 } (@{$view->columns}, @columns_extra);
    grep { $view_layouts{$_->{id}} } $self->all(%options);
}

# Returns what a user can do to the whole data set. Individual
# permissions for columns are contained in the column class.
sub user_can
{   my ($self, $permission) = @_;
    return 1 if $self->user_permission_override;
    $self->_user_permissions_overall->{$permission};
}

# Whether the user has got any sort of access
sub user_can_anything
{   my $self = shift;
    !! keys %{$self->_user_permissions_overall};
}

has referred_by => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_referred_by
{   my $self = shift;
    [
        $self->schema->resultset('Layout')->search({
            'child.instance_id' => $self->instance_id,
        },{
            join => {
                curval_fields_parents => 'child',
            },
            distinct => 1,
        })->all
    ];
}

sub _user_perm_search
{   my ($self, $type, $user_id) = @_;

    if ($type eq 'table')
    {
        return $self->schema->resultset('User')->search({
            'me.id'                       => $user_id,
            'instance_groups.instance_id' => $self->instance_id,
        },
        {
            prefetch => {
                user_groups => {
                    group => 'instance_groups',
                }
            },
        });
    }
    elsif ($type eq 'column')
    {
        return $self->schema->resultset('User')->search({
            'me.id'              => $user_id,
        },
        {
            prefetch => {
                user_groups => {
                    group => {
                        layout_groups => 'layout',
                    },
                }
            },
        });
    }
    else {
        panic "Invalid type $type";
    }
}

has global_view_summary => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_global_view_summary
{   my $self = shift;
    my @views = $self->schema->resultset('View')->search({
        -or => [
            global   => 1,
            is_admin => 1,
        ],
        instance_id => $self->instance_id,
    },{
        order_by => 'me.name',
    })->all;
    \@views;
}

sub export
{   my $self = shift;
    +{
        name                       => $self->name,
        homepage_text              => $self->homepage_text,
        homepage_text2             => $self->homepage_text2,
        sort_layout_id             => $self->sort_layout_id,
        sort_type                  => $self->sort_type,
    };
}

sub purge
{   my $self = shift;

    GADS::Graphs->new(schema => $self->schema, layout => $self)->purge;
    GADS::MetricGroups->new(schema => $self->schema, instance_id => $self->instance_id)->purge;
    GADS::Views->new(schema => $self->schema, instance_id => $self->instance_id, user => undef, layout => $self)->purge;

    $_->delete foreach reverse $self->all(order_dependencies => 1);

    $self->schema->resultset('UserLastrecord')->delete;
    $self->schema->resultset('Record')->search({
        instance_id => $self->instance_id,
    },{
        join => 'current',
    })->delete;
    $self->schema->resultset('Current')->search({
        instance_id => $self->instance_id,
    })->delete;
    $self->_rset->delete;
}

1;

