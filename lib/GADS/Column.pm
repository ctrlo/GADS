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
use Log::Report 'linkspace';
use String::CamelCase qw(camelize);
use GADS::DateTime;
use GADS::DB;
use GADS::Filter;
use GADS::Instance;
use GADS::Type::Permission;
use GADS::View;

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

has instance => (
    is  => 'lazy',
);

has instance_id => (
    is  => 'lazy',
    isa => Int,
);

has from_id => (
    is      => 'rw',
    trigger => sub {
        my ($self, $value) = @_;
        # Column needs to be built from its sub-class, otherwise methods only
        # relavent to that type will not be available
        ref $self eq 'GADS::Column'
            and panic "from_id cannot be called on raw GADS::Column object";
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

has name_short => (
    is  => 'rw',
    isa => Maybe[Str],
);

has type => (
    is  => 'rw',
    isa => sub {
        $_[0] eq 'id' || grep { $_[0] eq $_ } GADS::Column::types
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
    is      => 'lazy',
    isa     => AnyOf[Str, HashRef],
    clearer => 1,
);

has subjoin => (
    is => 'lazy',
);

sub _build_subjoin
{   my $self = shift;
    return unless ref $self->join;
    my ($temp, $subjoin) = %{$self->join};
    $subjoin;
}

has fixedvals => (
    is  => 'rw',
    isa => Bool,
);

has can_multivalue => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

# Whether the joins for this column type can be different depending on the
# columns configuration.
has variable_join => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has has_multivalue_plus => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has multivalue => (
    is      => 'rw',
    isa     => Bool,
    coerce  => sub { $_[0] ? 1 : 0 },
    default => 0,
);

has options => (
    is        => 'rwp',
    isa       => HashRef,
    lazy      => 1,
    builder   => 1,
    clearer   => 1,
    predicate => 1,
);

sub _build_options
{   my $self = shift;
    my $options = {};
    foreach my $option_name (@{$self->option_names})
    {
        $options->{$option_name} = $self->$option_name;
    }
    $options;
}

has option_names => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
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

has filter => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        GADS::Filter->new;
    },
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

# Whether this type can have some sort of sensible addition/subtraction
# operation performed on it
has addable => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
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

# Used when searching for a value's index value as opposed to string value
# (e.g. enums)
has value_field_as_index => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    default => undef,
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
            id        => 'GADS::Datum::ID',
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
    clearer => 1,
    builder => sub {
        my $self = shift;
        return [] if $self->userinput;
        my @depends = $self->schema->resultset('LayoutDepend')->search({
            layout_id => $self->id,
        })->all;
        [ map {$_->get_column('depends_on')} @depends ];
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

# Whether this column type has a typeahead when inputting filter values
has has_filter_typeahead => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has dateformat => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->layout->config->dateformat;
    },
);

# Used to store flags that we might want to store when the record is processed
has flags => (
    is      => 'rwp',
    isa     => HashRef,
    default => sub { +{} },
);

has _rset => (
    is      => 'rwp',
    lazy    => 1,
    builder => 1,
);

sub _build__rset
{   my $self = shift;
    $self->schema->resultset('Layout')->find($self->id);
}

sub parse_date
{   my ($self, $value) = @_;
    return if ref $value; # Will cause CLDR parser to bork
    # Check whether it's a CURDATE first
    my $dt = GADS::Filter->parse_date_filter($value);
    return $dt if $dt;
    $value && GADS::DateTime::parse_datetime($value);
}

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

sub group_has
{   my ($self, $group_id, $perm) = @_;
    my $perms = $self->permissions->{$group_id}
        or return 0;
    (grep { $_->short eq $perm } @$perms) ? 1 : 0;
}

sub group_summary
{   my ($self, $permission) = @_;
    map { $_->group->name } $self->schema->resultset('LayoutGroup')->search({
        layout_id  => $self->id,
        permission => $permission,
    },{
        prefetch => 'group',
    })->all;
}

sub _build_instance
{   my $self = shift;
    GADS::Instance->new(
        id     => $self->instance_id,
        schema => $self->schema,
    );
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
    $self->name_short($original->{name_short});
    $self->optional($original->{optional});
    $self->remember($original->{remember});
    $self->isunique($original->{isunique});
    $self->multivalue($original->{multivalue} ? 1 : 0) if $self->can_multivalue;
    $self->position($original->{position});
    $self->helptext($original->{helptext});
    my $options = $original->{options} ? decode_json($original->{options}) : {};
    $self->_set_options($options);
    $self->description($original->{description});
    $self->field("field$original->{id}");
    $self->type($original->{type});
    $self->display_field($original->{display_field});
    $self->display_regex($original->{display_regex});
    
    # XXX Move to Column::Enum, Tree and Person classes?
    if ($self->type eq 'enum' || $self->type eq 'tree' || $self->type eq 'person' || $self->type eq 'file')
    {
        $self->sprefix('value');
        $self->fixedvals(1);
    }
    elsif ($self->type eq 'curval')
    {
        $self->fixedvals(1);
        $self->sprefix($self->field);
        $self->filter->as_json($original->{filter});
        $self->filter->layout($self->layout_parent);
    }
    else {
        $self->sprefix($self->field);
    }

    $self->table(camelize $self->type);
}

# Overriden for most columns
sub _build_join
{   my $self = shift;
    return $self->field;
}

# Overridden where required
sub filter_value_to_text
{   my ($self, $value) = @_;
    return $value;
}

# Overridden where required
sub sort_columns
{   my $self = shift;
    ($self);
}

# Whether the sort columns when added should be added with a parent, and
# if so what is the paremt
sub sort_parent
{   my $self = shift;
    return undef; # default no, undef in case used in arrays
}

# Overridden in child classes. This function is used
# to cleanup specialist column data when a column
# is deleted
sub cleanup {}

# ID for the filter
has filter_id => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->id },
);

# Name of the column for the filter
has filter_name => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->name },
);

# Generic subroutine to fetch all multivalues for a table. Designed to satisfy
# most standard tables. Overridden for anything complicated.
sub fetch_multivalues
{   my ($self, $record_ids) = @_;

    my $select = {
        join => 'layout',
    };
    if (ref $self->join)
    {
        my ($left, $prefetch) = %{$self->join}; # Prefetch table is 2nd part of join
        $select->{prefetch} = $prefetch;
    }
    my $m_rs = $self->schema->resultset($self->table)->search({
        'me.record_id'      => $record_ids,
        'layout.multivalue' => 1,
    }, $select);
    $m_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    $m_rs->all;
}

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

    # Now see if any linked fields depend on this one
    if (my @linked = $self->schema->resultset('Layout')->search({
            link_parent => $self->id
        })->all
    )
    {
        my @ln = map { $_->name } @linked;
        my $l  = join ', ', @ln;
        error __x"The following fields in another datasheet are linked to this field: {l}.
            Please remove these links before deletion of this field.", l => $l;
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
    # Same again for fields with filter
    foreach my $col ($self->schema->resultset('Layout')->search({
        filter => { '!=' => '{}' },
    })->all)
    {
        $col->filter or next;
        my $filtered = _filter_remove_colid($self, $col->filter);
        $col->update({ filter => $filtered });
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

sub write_special {} # Overridden in children
sub after_write_special {} # Overridden in children

sub write
{   my ($self, %options) = @_;

    my $guard = $self->schema->txn_scope_guard;

    my $newitem;
    $newitem->{name} = $self->name
        or error __"Please enter a name for item";
    grep { $_->{name} eq $newitem->{name} } @{$self->layout->internal_columns}
        and error __x"{name} is a reserved name for a field", name => $newitem->{name};
    $newitem->{type} = $self->type
        or error __"Please select a type for the item";

    if ($newitem->{name_short} = $self->name_short)
    {
        # Check format
        $self->name_short =~ /^[a-z][_0-9a-z]*$/i
            or error __"Short names must begin with a letter and can only contain letters, numbers and underscores";
        # Check short name is unique
        my $search = {
            name_short  => $self->name_short,
        };
        if ($self->id)
        {
            # Don't search self if already in DB
            $search->{id}          = { '!=' => $self->id };
        }

        my $exists = $self->schema->resultset('Layout')->search($search)->next;
        $exists and error __x"Short name {short} must be unique but already exists for field \"{name}\"",
            short => $self->name_short, name => $exists->name;
    }

    # Check whether the parent linked field goes to a layout that has a curval
    # back to the current layout
    if ($self->link_parent_id)
    {
        my $link_parent = $self->schema->resultset('Layout')->find($self->link_parent_id);
        if ($link_parent->type eq 'curval')
        {
            foreach ($link_parent->curval_fields_parents)
            {
                error __x qq(Cannot link to column "{col}" which contains columns from this table),
                    col => $link_parent->name
                    if $_->child->instance_id == $self->instance_id;
            }
        }
    }

    $newitem->{optional}      = $self->optional;
    $newitem->{remember}      = $self->remember;
    $newitem->{isunique}      = $self->isunique;
    $newitem->{filter}        = $self->filter->as_json;
    $newitem->{multivalue}    = $self->multivalue if $self->can_multivalue;
    $newitem->{description}   = $self->description;
    $newitem->{helptext}      = $self->helptext;
    $newitem->{options}       = encode_json($self->options);
    $newitem->{link_parent}   = $self->link_parent_id;
    $newitem->{display_field} = $self->display_field;
    $newitem->{display_regex} = $self->display_regex;
    $newitem->{instance_id}   = $self->layout->instance_id;
    $newitem->{position}      = $self->position
        if $self->position; # Used on layout import

    my ($new_id, $rset);

    if (!$self->id)
    {
        $newitem->{id} = $self->set_id if $self->set_id;
        # Add at end of other items
        $newitem->{position} = ($self->schema->resultset('Layout')->get_column('position')->max || 0) + 1;
        $rset = $self->schema->resultset('Layout')->create($newitem);
        $new_id = $rset->id;
        $self->_set__rset($rset);
    }
    else {
        $rset = $self->schema->resultset('Layout')->find($self->id);
        $rset->update($newitem);
    }

    $self->write_special(rset => $rset, id => $new_id || $self->id, %options); # Write any column-specific params

    $guard->commit;

    if ($new_id)
    {
        $self->id($new_id);
        GADS::DB->add_column($self->schema, $self);
        # Ensure new column is properly added to layout
        $self->layout->clear;
    }
    $self->after_write_special(%options);

    $self->layout->clear_indexes;
}

sub user_can
{   my ($self, $permission) = @_;
    return 1 if $self->user_permission_override;
    return 1 if $self->internal && $permission eq 'read';
    return 0 if !$self->userinput && $permission ne 'read'; # Can't write to code fields
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
{   my ($self, %options) = @_;


    # These set from web form
    my $groups         = $options{groups};
    my $read           = $options{read};
    my $write_new      = $options{write_new};
    my $write_existing = $options{write_existing};

    # This for setting permissions directly
    my $permissions = $options{permissions};

    if ($permissions)
    {
        $groups = [ keys %$permissions ];
    }
    else {
        foreach my $group_id (@$groups)
        {
            my @perms;

            # For each permission type, see if it is set (a value that is not the
            # next hidden placeholder value). If it is, shift the actual value, to
            # make sure that the next value is the next placeholder

            shift @$read eq 'holder' or panic "Missing holder for read";
            push @perms, 'read'
                if $read->[0] && $read->[0] ne 'holder' && shift @$read;

            shift @$write_new eq 'holder' or panic "Missing holder for write_new";
            push @perms, 'write_new'
                if $write_new->[0] && $write_new->[0] ne 'holder' && shift @$write_new;

            shift @$write_existing eq 'holder' or panic "Missing holder for write_existing";
            push @perms, 'write_existing'
                if $write_existing->[0] && $write_existing->[0] ne 'holder' && shift @$write_existing;

            $permissions->{$group_id} = [@perms]
                if $group_id; # May not have been group selected in drop-down
        }
    }

    $groups = [ grep {$_} @$groups ]; # Remove permissions with blank submitted group

    # Search for any groups that were in the permissions but no longer exist
    my $search = {
        layout_id => $self->id,
    };
    $search->{group_id} = { '!=' => [ '-and', @$groups ] }
        if @$groups;
    push @$groups, $self->schema->resultset('LayoutGroup')->search($search,{
        select   => {
            max => 'group_id',
            -as => 'group_id',
        },
        as       => 'group_id',
        group_by => 'group_id',
    })->get_column('group_id')->all;

    foreach my $group_id (@$groups)
    {
        my $has_read;
        my @permissions = $permissions->{$group_id} ? @{$permissions->{$group_id}} : ();
        foreach my $permission (@permissions)
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
        foreach (qw/approve_new approve_existing write_new_no_approval write_existing_no_approval/)
        {
            push @permissions, $_ if !$options{permissions} && !exists $options{$_};
        }
        $search->{permission} = { '!=' => [ '-and', @permissions ] } if @permissions;
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
}

sub _filter_remove_colid
{   my ($self, $json) = @_;
    my $filter_dec = decode_json $json;
    _filter_remove_colid_decoded($filter_dec, $self->id);
    # An AND with empty rules causes JSON filter to have JS error
    $filter_dec = {} if !$filter_dec->{rules} || !@{$filter_dec->{rules}};
    encode_json $filter_dec;
}

# Recursively find all tables in a nested filter
sub _filter_remove_colid_decoded
{   my ($filter, $colid) = @_;

    if (my $rules = $filter->{rules})
    {
        # Filter has other nested filters
        @$rules = grep { _filter_remove_colid_decoded($_, $colid) && (!$_->{rules} || @{$_->{rules}}) } @$rules;
    }
    $filter->{id} && $colid == $filter->{id} ? 0 : 1;
}

sub validate
{   my ($self, $value) = @_;
    1; # Overridden in child classes
}

sub validate_search
{   shift->validate(@_);
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

