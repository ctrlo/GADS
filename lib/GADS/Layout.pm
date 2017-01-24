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
use Log::Report;
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
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has name => (
    is      => 'lazy',
    isa     => Str,
    clearer => 1,
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

# The permissions the logged-in user has, for the whole data set
has user_permissions => (
    is        => 'rw',
    isa       => HashRef,
    predicate => 1,
);

# The permissions for all users, as a cache, for multiple
# requests to get_user_perms
has user_permissions_cache => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { {} },
);

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

has internal_columns => (
    is      => 'ro',
    isa     => ArrayRef,
    builder => sub {
        [
            {
                id         => -1,
                name       => 'ID',
                name_short => 'id',
                table      => 'current',
                column     => 'id',
                isunique   => 1,
            },
            {
                id     => -2,
                name   => 'Version Datetime',
                table  => 'record',
                column => 'created',
                isunique => 0,
            },
            {
                id     => -3,
                name   => 'Version User ID',
                table  => 'record',
                column => 'created_by',
                isunique => 0,
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
    $self->clear_indexes;
}

# Instantiate new class. This builds a list of all
# columns, so that it's cached for any later function
sub _build_columns
{   my $self = shift;

    my $cols_rs = $self->schema->resultset('Layout')->search(
    {
        'me.instance_id' => $self->instance_id,
    },{
        order_by => ['me.position', 'enumvals.id'],
        join     => 'enumvals',
        prefetch => ['calcs', 'rags', 'link_parent'],
    });

    $cols_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');

    my @allcols = $cols_rs->all;

    my @return;
    foreach my $col (@allcols)
    {
        my $class = "GADS::Column::".camelize $col->{type};
        my $column = $class->new(
            set_values               => $col,
            user_permission_override => $self->user_permission_override,
            schema                   => $self->schema,
            layout                   => $self
        );
        push @return, $column;
    }

    my ($perms, $overall_permissions);
    if ($self->user)
    {
        ($perms, $overall_permissions) = $self->get_user_perms($self->user->{id});
        $self->user_permissions($overall_permissions);
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
        if ($perms)
        {
            if (my $perm = $perms->{$col->id})
            {
                $col->user_permissions($perm);
            }
        }
    }

    # Add on special internal columns
    foreach my $internal (@{$self->internal_columns})
    {
        push @return, GADS::Column->new(
            id                       => $internal->{id},
            name                     => $internal->{name},
            name_short               => $internal->{name_short},
            isunique                 => $internal->{isunique},
            table                    => camelize($internal->{table}),
            sprefix                  => $internal->{table},
            value_field              => $internal->{column},
            internal                 => 1,
            user_permission_override => $self->user_permission_override,
            schema                   => $self->schema,
            layout                   => $self,
        );
    }

    \@return;
}

sub _build_name
{   my $self = shift;
    my $instance = $self->schema->resultset('Instance')->find($self->instance_id);
    $instance->name;
}

sub get_user_perms
{   my ($self, $user_id) = @_;
    my $cache = $self->user_permissions_cache;
    unless ($cache->{$user_id})
    {
        # Construct a hash with all the permissions for the different columns
        my $perms_rs = $self->schema->resultset('User')->search({
            'me.id' => $user_id,
        }, {
            prefetch => { user_groups => { group => 'layout_groups' } },
        });
        $perms_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
        my ($user_perms) = $perms_rs->all; # The overall user. Only one due to query.
        my %perms; # Hash of different columns and their permissions
        my %overall_permissions; # Flat structure of all user permissions for whole layout
        foreach my $group (@{$user_perms->{user_groups}}) # For each group the user has
        {
            foreach my $layout_group (@{$group->{group}->{layout_groups}}) # For each column in that group
            {
                # Push the actual permission onto an array
                $perms{$layout_group->{layout_id}} ||= [];
                push @{$perms{$layout_group->{layout_id}}}, $layout_group->{permission};
                $overall_permissions{$layout_group->{permission}} = 1;
            }
        }
        $cache->{$user_id}->{perms} = \%perms;
        $cache->{$user_id}->{overall_permissions} = \%overall_permissions;
    }
    wantarray ? ($cache->{$user_id}->{perms}, $cache->{$user_id}->{overall_permissions}) : $cache->{$user_id}->{perms};
}

sub all
{   my ($self, %options) = @_;

    my $type = $options{type};

    my @columns = @{$self->columns};
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
        $_->id => $_->depends_on;
    } @columns;

    my $source = Algorithm::Dependency::Source::HoA->new(\%deps);
    my $dep = Algorithm::Dependency::Ordered->new(source => $source)
        or die 'Failed to set up dependency algorithm';
    my @order = @{$dep->schedule_all};
    map { $self->columns_index->{$_} } @order;
}

sub position
{   my ($self, $position) = @_;
    my $count;
    foreach my $id (@$position)
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

# XXX Should move this into a user class at some point.
# Returns what a user can do to the whole data set. Individual
# permissions for columns are contained in the column class.
sub user_can
{   my ($self, $permission) = @_;
    return 1 if $self->user_permission_override;
    if (!$self->has_user_permissions)
    {
        # Full layout has not been built. Shortcut to just a simple
        # SQL query instead
        return $self->schema->resultset('UserGroup')->search({
            user_id    => $self->user->{id},
            permission => $permission,
        },{
            join => { group => 'layout_groups' },
        })->count;
    }
    $self->user_permissions->{$permission};
}

1;

