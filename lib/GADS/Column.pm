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
{ qw(date daterange string intgr person tree enum file rag calc) }

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
);

has from_id => (
    is      => 'rw',
    trigger => sub {
        my ($self, $value) = @_;
        my $cols_rs = $self->schema->resultset('Layout')->search({
            'me.id' => $value,
        },{
            order_by => ['me.position', 'enumvals.id'],
            prefetch => ['enumvals', 'calcs', 'rags', 'file_options' ],
        });

        $cols_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
        my ($col) = $cols_rs->all;
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
    isa => sub {
        return unless $_[0];
        $_[0] =~ /(string|date|integer)/
            or error __x"Bad return type {type}", type => $_[0];
    },
    lazy    => 1,
    builder => sub { $_[0]->type eq 'date' ? 'date' : undef }, # Default to date for date column
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
    is     => 'rw',
    isa    => Bool,
    coerce => sub { $_[0] ? 1 : 0 },
);

has userinput => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    default => 1,
);

has numeric => (
    is  => 'rw',
    isa => Bool,
);

has optional => (
    is     => 'rw',
    isa    => Bool,
    coerce => sub { $_[0] ? 1 : 0 },
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

has depended_by => (
    is  => 'rw',
    isa => ArrayRef,
);

has helptext => (
    is  => 'rw',
    isa => Maybe[Str],
);

has suffix => (
    is   => 'rw',
    isa  => Str,
    lazy => 1,
    builder => sub {
        $_[0]->type eq 'daterange'
        ? '(\.from|\.to)?(\.year|\.month|\.day)?'
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
        );
        $classes{$_[0]->type};
    },
);

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
        [ map {$_->depends_on} @depends ];
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

sub build_values
{   my ($self, $original) = @_;

    $self->id($original->{id});
    $self->name($original->{name});
    $self->optional($original->{optional});
    $self->remember($original->{remember});
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
    else {
        $self->sprefix($self->field);
        $self->join($self->field);
    }

    $self->table(camelize $self->type);
    $self->numeric($self->type eq 'date' || $self->type eq 'intgr');
}

sub delete
{   my $self = shift;

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
    if (my @deps = $self->schema->resultset('LayoutDepend')->search({
            depends_on => $self->id
        })->all
    )
    {
        my @depsn = map { $_->layout->name } @deps;
        my $dep   = join ', ', @depsn;
        error __x"The following fields contain this field in their formula: {dep}.
            Please remove these before deletion.", dep => $dep;
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

    $self->schema->resultset('ViewLayout')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('Filter')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('Person')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('Calc')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('Calcval')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('Rag')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('Ragval')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('AlertCache')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('Sort')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('Intgr')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('String')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('Enum')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('LayoutDepend')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('LayoutGroup')->search({ layout_id => $self->id })->delete;
    # XXX The following should be done in ::Enum, except it won't be if the column
    # is not a different type. This may still error due to parents etc
    $self->schema->resultset('Enumval')->search({ layout_id => $self->id })->delete;

    $self->schema->resultset('Instance')->search({ sort_layout_id => $self->id })->update({sort_layout_id => undef});;
    $self->schema->resultset($self->table)->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('Layout')->find($self->id)->delete;
}

sub write
{   my $self = shift;

    my $newitem;
    $newitem->{name} = $self->name
        or error __"Please enter a name for item";
    $newitem->{type} = $self->type
        or error __"Please select a type for the item";
    $newitem->{optional}      = $self->optional;
    $newitem->{remember}      = $self->remember;
    $newitem->{description}   = $self->description;
    $newitem->{helptext}      = $self->helptext;
    $newitem->{display_field} = $self->display_field;
    $newitem->{display_regex} = $self->display_regex;
    $newitem->{position}      = $self->position
        if $self->position; # Used on layout import
   
    if ($self->id)
    {
        $self->schema->resultset('Layout')->find($self->id)->update($newitem);
    }
    else {
        $newitem->{id} = $self->set_id if $self->set_id;
        my $id = $self->schema->resultset('Layout')->create($newitem)->id;
        $self->id($id);
    }

    GADS::DB->add_column($self->schema, $self);
}

sub user_can
{   my ($self, $permission) = @_;
    return 1 if $self->user_permission_override;
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

1;

