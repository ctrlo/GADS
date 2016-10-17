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

package GADS::Column;

use JSON qw(decode_json encode_json);
use Log::Report;
use String::CamelCase qw(camelize);
use GADS::DB;
use GADS::Type::Permission;
use GADS::Util qw(:all);

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

use namespace::clean; # Otherwise Enum clashes with MooseLike

sub types
{ qw(date daterange string intgr person tree enum file rag calc curval) }

has schema => (
    is       => 'rw',
    required => 1,
);

# Needed for update of cached columns
has user => (
    is => 'rw',
);

# All permissions for this column
has permissions => (
    is  => 'lazy',
    isa => HashRef,
);

# The permissions the logged-in user has
has user_permissions => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

has user_permission_override => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

# Needed for update of cached columns
has layout => (
    is       => 'ro',
    weak_ref => 1,
);

has instance_id => (
    is  => 'lazy',
    isa => Int,
);

has from_id => (
    is      => 'rw',
    trigger => sub {
        my ($self, $value) = @_;
        my $cols_rs = $self->schema->resultset('Layout')->search({
            'me.id'          => $value,
            'me.instance_id' => $self->instance_id,
        },{
            order_by => ['me.position', 'enumvals.id'],
            prefetch => ['enumvals', 'calcs', 'rags', 'file_options' ],
        });

        $cols_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
        my ($col) = $cols_rs->all;
        $col or error __x"Field ID {id} not found", id => $value;
        $self->set_values($col);
    },
);

has set_values => (
    is      => 'rw',
    trigger => sub { shift->build_values(@_) },
);

has id => (
    is  => 'rw',
    isa => Int,
);

has internal => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

# Used to force a database ID on creation (used in layout import)
has set_id => (
    is  => 'rw',
    isa => Maybe[Int],
);

has name => (
    is  => 'rw',
    isa => Str,
);

has type => (
    is  => 'rw',
    isa => sub {
        grep { $_[0] eq $_ } GADS::Column::types
            or error __x"Invalid field type {type}", type => $_[0];
    },
);

# e.g. calc type can return date or integer
has return_type => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { 'string' },
);

has table => (
    is  => 'rw',
    isa => Str,
);

has join => (
    is  => 'rw',
    isa => AnyOf[Str, HashRef],
);

has fixedvals => (
    is  => 'rw',
    isa => Bool,
);

has ordering => (
    is  => 'rw',
    isa => Maybe[Str],
);

has position => (
    is  => 'rw',
    isa => Maybe[Int],
);

has sprefix => (
    is  => 'rw',
    isa => Str,
);

has remember => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    default => 0,
    coerce  => sub { $_[0] ? 1 : 0 },
);

has isunique => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    default => 0,
    coerce  => sub { $_[0] ? 1 : 0 },
);

has userinput => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

has numeric => (
    is   => 'rw',
    isa  => Bool,
    lazy => 1,
);

# Whether the data is stored as a string. If so, we need to check for both
# empty string and null values to test if empty
has string_storage => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    default => 0,
);

has optional => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    default => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
);

has description => (
    is  => 'rw',
    isa => Maybe[Str],
);

has display_field => (
    is  => 'rw',
    isa => Maybe[Int],
);

has display_regex => (
    is  => 'rw',
    isa => Maybe[Str],
);

has display_depended_by => (
    is  => 'rw',
    isa => ArrayRef,
);

has helptext => (
    is  => 'rw',
    isa => Maybe[Str],
);

has link_parent => (
    is     => 'rw',
);

has link_parent_id => (
    is     => 'rw',
    isa    => Maybe[Int],
    coerce => sub { $_[0] || undef }, # String from form submit
);

has suffix => (
    is   => 'rw',
    isa  => Str,
    lazy => 1,
    builder => sub {
        $_[0]->return_type eq 'date' || $_[0]->return_type eq 'daterange'
        ? '(\.from|\.to|\.value)?(\.year|\.month|\.day)?'
        : $_[0]->type eq 'tree'
        ? '(\.level[0-9]+)?'
        : '';
    },
);

has field => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    builder => sub { "field".$_[0]->id },
);

has value_field => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => 'value',
);

# Used to provide a blank template for row insertion (to blank existing
# values). Only used in calc at time of writing
has blank_row => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        +{
            $self->value_field => undef,
        };
    },
);

has class => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => sub {
        my %classes = (
            date      => 'GADS::Datum::Date',
            daterange => 'GADS::Datum::Daterange',
            string    => 'GADS::Datum::String',
            intgr     => 'GADS::Datum::Integer',
            person    => 'GADS::Datum::Person',
            tree      => 'GADS::Datum::Tree',
            enum      => 'GADS::Datum::Enum',
            file      => 'GADS::Datum::File',
            rag       => 'GADS::Datum::Rag',
            calc      => 'GADS::Datum::Calc',
            curval    => 'GADS::Datum::Curval',
        );
        $classes{$_[0]->type};
    },
);

# Which fields this column depends on
has depends_on => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    builder => sub {
        my $self = shift;
        return [] if $self->userinput;
        my @depends = $self->schema->resultset('LayoutDepend')->search({
            layout_id => $self->id,
        })->all;
        [ map {$_->get_column('depends_on')} @depends ];
    },
    trigger => sub {
        my ($self, $new) = @_;
        $self->schema->resultset('LayoutDepend')->search({
            layout_id => $self->id
        })->delete;
        foreach (@$new)
        {
            $self->schema->resultset('LayoutDepend')->create({
                layout_id  => $self->id,
                depends_on => $_,
            });
        }
    },
);

# Which columns depend on this field
has depended_by => (
    is      => 'lazy',
    isa     => ArrayRef,
);

sub _build_depended_by
{   my $self = shift;
    my @depended = $self->schema->resultset('LayoutDepend')->search({
        depends_on => $self->id,
    })->all;
    [ map {$_->get_column('layout_id')} @depended ];
}

has hascache => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    builder => sub {
        my @cached = qw(rag calc person daterange);
        my $type   = $_[0]->type;
        grep( /^$type$/, @cached ) ? 1 : 0;
    },
);

sub _build_permissions
{   my $self = shift;
    my @all = $self->schema->resultset('LayoutGroup')->search({
        layout_id => $self->id,
    });
    my %perms;
    foreach my $p (@all)
    {
        $perms{$p->group_id} ||= [];
        push @{$perms{$p->group_id}}, GADS::Type::Permission->new(
            short => $p->permission
        );
    }
    \%perms;
}

sub _build_instance_id
{   my $self = shift;
    $self->layout
        or panic "layout is not set - specify instance_id on creation instead?";
    $self->layout->instance_id;
}

sub build_values
{   my ($self, $original) = @_;

    my $link_parent = $original->{link_parent};
    if (ref $link_parent)
    {
        my $class = "GADS::Column::".camelize $link_parent->{type};
        my $column = $class->new(
            set_values               => $link_parent,
            user_permission_override => $self->user_permission_override,
            schema                   => $self->schema,
            layout                   => $self->layout,
        );
        $self->link_parent($column);
    }
    else {
        $self->link_parent_id($original->{link_parent});
    }
    $self->id($original->{id});
    $self->name($original->{name});
    $self->optional($original->{optional});
    $self->remember($original->{remember});
    $self->isunique($original->{isunique});
    $self->position($original->{position});
    $self->helptext($original->{helptext});
    $self->description($original->{description});
    $self->field("field$original->{id}");
    $self->type($original->{type});
    $self->display_field($original->{display_field});
    $self->display_regex($original->{display_regex});
    
    # XXX Move to Column::Enum, Tree and Person classes?
    if ($self->type eq 'enum' || $self->type eq 'tree' || $self->type eq 'person' || $self->type eq 'file')
    {
        $self->sprefix('value');
        $self->join({$self->field => 'value'});
        $self->fixedvals(1);
    }
    elsif ($self->type eq 'curval')
    {
        my @join = map { $_->join } @{$self->curval_fields};
        $self->join({
            $self->field => {
                value => {
                    record => [@join]
                }
            }
        });
        $self->fixedvals(1);
        $self->sprefix($self->field);
    }
    else {
        $self->sprefix($self->field);
        $self->join($self->field);
    }

    $self->table(camelize $self->type);
}

# Overridden in child classes. This function is used
# to cleanup specialist column data when a column
# is deleted
sub cleanup {}

sub delete
{   my $self = shift;

    my $guard = $self->schema->txn_scope_guard;

    # First see if any views are conditional on this field
    if (my @deps = $self->schema->resultset('Layout')->search({
            display_field => $self->id
        })->all
    )
    {
        my @depsn = map { $_->name } @deps;
        my $dep   = join ', ', @depsn;
        error __x"The following fields are conditional on this field: {dep}.
            Please remove these conditions before deletion.", dep => $dep;
    }

    # Next see if any calculated fields are dependent on this
    if (@{$self->depended_by})
    {
        my @depsn = map { $self->layout->column($_)->name } @{$self->depended_by};
        my $dep   = join ', ', @depsn;
        error __x"The following fields contain this field in their formula: {dep}.
            Please remove these before deletion.", dep => $dep;
    }

    # Now see if any Curval fields depend on this field
    if (my @parents = $self->schema->resultset('CurvalField')->search({
            child_id => $self->id
        })->all
    )
    {
        my @pn = map { $_->parent->name } @parents;
        my $p  = join ', ', @pn;
        error __x"The following fields in another datasheet refer to this field: {p}.
            Please remove these references before deletion of this field.", p => $p;
    }

    if (my @graphs = $self->schema->resultset('Graph')->search(
            [
                { x_axis => $self->id   },
                { y_axis => $self->id   },
                { group_by => $self->id },
            ]
        )->all
    )
    {
        my $g = join(q{, }, map{$_->title} @graphs);
        error __x"The following graphs references this field: {graph}. Please update them before deletion."
            , graph => $g;
    }

    # Remove this column from any filters defined on views
    foreach my $filter ($self->schema->resultset('Filter')->search({
        layout_id      => $self->id,
    })->all)
    {
        my $filtered = _filter_remove_colid($self, $filter->view->filter);
        $filter->view->update({ filter => $filtered });
    };

    # Clean up any specialist data for all column types. The column's
    # type may have changed during its life, but the data may not
    # have been removed on change, so we have to check all classes.
    foreach my $type ($self->types)
    {
        my $class = "GADS::Column::".camelize $type;
        $class->cleanup($self->schema, $self->id);
    }

    $self->schema->resultset('ViewLayout')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('Filter')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('AlertCache')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('AlertSend')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('Sort')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('LayoutDepend')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('LayoutGroup')->search({ layout_id => $self->id })->delete;

    $self->schema->resultset('Instance')->search({ sort_layout_id => $self->id })->update({sort_layout_id => undef});;
    $self->schema->resultset('Layout')->find($self->id)->delete;

    $guard->commit;
}

sub write
{   my $self = shift;

    my $newitem;
    $newitem->{name} = $self->name
        or error __"Please enter a name for item";
    grep { $_->{name} eq $newitem->{name} } @{$self->layout->internal_columns}
        and error __x"{name} is a reserved name for a field", name => $newitem->{name};
    $newitem->{type} = $self->type
        or error __"Please select a type for the item";
    $newitem->{optional}      = $self->optional;
    $newitem->{remember}      = $self->remember;
    $newitem->{isunique}      = $self->isunique;
    $newitem->{description}   = $self->description;
    $newitem->{helptext}      = $self->helptext;
    $newitem->{link_parent}   = $self->link_parent_id;
    $newitem->{display_field} = $self->display_field;
    $newitem->{display_regex} = $self->display_regex;
    $newitem->{instance_id}   = $self->layout->instance_id;
    $newitem->{position}      = $self->position
        if $self->position; # Used on layout import
   
    if ($self->id)
    {
        $self->schema->resultset('Layout')->find($self->id)->update($newitem);
    }
    else {
        $newitem->{id} = $self->set_id if $self->set_id;
        # Add at end of other items
        $newitem->{position} = ($self->schema->resultset('Layout')->get_column('position')->max || 0) + 1;
        my $id = $self->schema->resultset('Layout')->create($newitem)->id;
        $self->id($id);
    }

    GADS::DB->add_column($self->schema, $self);
}

sub user_can
{   my ($self, $permission) = @_;
    return 1 if $self->user_permission_override;
    return 1 if $self->internal && $permission eq 'read';
    return 1 if grep { $_ eq $permission } @{$self->user_permissions};
    if ($permission eq 'write') # shortcut
    {
        return 1 if grep { $_ eq 'write_new' || $_ eq 'write_existing' }
            @{$self->user_permissions};
    }
    0;
}

# Whether a particular user ID has a permission for this column
sub user_id_can
{   my ($self, $user_id, $permission) = @_;
    my $perms = $self->layout->get_user_perms($user_id)->{$self->id}
        or return;
    grep { $_ eq $permission } @$perms;
}

sub set_permissions
{   my ($self, $group_id, $permissions) = @_;
    my $has_read;
    foreach my $permission (@$permissions)
    {
        $has_read = 1 if $permission eq 'read';
        # Unique constraint on table. Catch existing.
        try {
            $self->schema->resultset('LayoutGroup')->create({
                layout_id  => $self->id,
                group_id   => $group_id,
                permission => $permission,
            });
        };
        # Log any messages from try block, but only as trace
        $@->reportAll(reason => 'TRACE');
    }

    # Before we do the catch-all delete, see if there is currently a
    # read permission there which is about to be removed.
    my $read_removed = !$has_read && $self->schema->resultset('LayoutGroup')->search({
        group_id   => $group_id,
        layout_id  => $self->id,
        permission => 'read',
    })->count;

    # Delete those no longer there
    my $search = { group_id => $group_id, layout_id => $self->id };
    $search->{permission} = { '!=' => [ '-and', @$permissions ] } if @$permissions;
    $self->schema->resultset('LayoutGroup')->search($search)->delete;

    # See if any read permissions have been removed. If so, we need
    # to remove them from the relevant filters and sorts. The views themselves
    # don't matter, as they won't be shown anyway.
    if ($read_removed)
    {
        # First the sorts
        foreach my $sort ($self->schema->resultset('Sort')->search({
            layout_id      => $self->id,
            'view.user_id' => { '!=' => undef },
        }, {
            prefetch => 'view',
        })->all)
        {
            # For each sort on this column, which no longer has read.
            # See if user attached to this view still has access with
            # another group
            $sort->delete unless $self->user_id_can($sort->view->user_id, 'read');
        }
        # Then the filters
        foreach my $filter ($self->schema->resultset('Filter')->search({
            layout_id      => $self->id,
            'view.user_id' => { '!=' => undef },
        }, {
            prefetch => 'view',
        })->all)
        {
            # For each sort on this column, which no longer has read.
            # See if user attached to this view still has access with
            # another group
            unless ($self->user_id_can($filter->view->user_id, 'read'))
            {
                # Filter cache
                $filter->delete;
                # Alert cache
                $self->schema->resultset('AlertCache')->search({
                    layout_id => $self->id,
                    view_id   => $filter->view_id,
                })->delete;
                # Column in the view
                $self->schema->resultset('ViewLayout')->search({
                    layout_id => $self->id,
                    view_id   => $filter->view_id,
                })->delete;
                # And the JSON filter itself
                my $filtered = _filter_remove_colid($self, $filter->view->filter);
                $filter->view->update({ filter => $filtered });
            }
        }
    }
}

sub _filter_remove_colid
{   my ($self, $json) = @_;
    my $filter_dec = decode_json $json;
    _filter_remove_colid_decoded($filter_dec, $self->id);
    # An AND with empty rules causes JSON filter to have JS error
    $filter_dec = {} unless @{$filter_dec->{rules}};
    encode_json $filter_dec;
}

# Recursively find all tables in a nested filter
sub _filter_remove_colid_decoded
{   my ($filter, $colid) = @_;

    if (my $rules = $filter->{rules})
    {
        # Filter has other nested filters
        @$rules = grep { _filter_remove_colid_decoded($_, $colid) } @$rules;
    }
    $filter->{id} && $colid == $filter->{id} ? 0 : 1;
}

sub validate
{   my ($self, $value) = @_;
    1; # Overridden in child classes
}

sub values_beginning_with
{   my ($self, $match_string) = @_;

    my $resultset = $self->resultset_for_values;
    my @value;
    my $value_field = 'me.'.$self->value_field;
    my $search = $match_string
        ? {
            $value_field => {
                -like => "${match_string}%",
            },
        } : {};
    if ($resultset) {
        $match_string =~ s/([_%])/\\$1/g;
        my $match_result = $resultset->search($search,
            {
                rows   => 10,
                select => {
                    max => $value_field,
                    -as => $value_field,
                }
            },
        );
        @value = $match_result->get_column($value_field)->all;
    }
    return @value;
}

# The regex that will match the column in a calc/rag code definition
sub code_regex
{   my $self  = shift;
    my $name  = $self->name; my $suffix = $self->suffix;
    qr/\[\^?\Q$name\E$suffix\Q]/i;
}

1;

