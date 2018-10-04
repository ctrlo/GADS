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
use GADS::Groups;
use GADS::Type::Permission;
use GADS::View;
use MIME::Base64 /encode_base64/;

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

use List::Compare ();

use namespace::clean; # Otherwise Enum clashes with MooseLike

with 'GADS::Role::Presentation::Column';

sub types
{ qw(date daterange string intgr person tree enum file rag calc curval autocur) }

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

has hidden => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

# Used when updating fields externally and a URL needs to be supplied for alert
# links
has base_url => (
    is => 'rw',
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
        $_[0] =~ /^(id|serial)$/ || grep { $_[0] eq $_ } GADS::Column::types
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
    is  => 'lazy',
    isa => Str,
);

sub _build_table
{   my $self = shift;
    camelize $self->type;
}

has fixedvals => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
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

has is_curcommon => (
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
    is  => 'lazy',
    isa => Str,
);

sub _build_sprefix
{   my $self = shift;
    $self->field;
}

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

has set_can_child => (
    is        => 'rw',
    isa       => Bool,
    predicate => 1,
    coerce    => sub { $_[0] ? 1 : 0 },
    trigger   => sub { shift->clear_can_child },
);

has can_child => (
    is      => 'lazy',
    isa     => Bool,
    coerce  => sub { $_[0] ? 1 : 0 },
    clearer => 1,
);

sub _build_can_child
{   my $self = shift;
    if (!$self->userinput)
    {
        # Code values always have their own child values if the record is a
        # child, so that we build based on the true values of the child record.
        # Therefore return true if this is a code value which depends on a
        # child column
        return 1 if $self->schema->resultset('LayoutDepend')->search({
            layout_id => $self->id,
            'depend_on.can_child' => 1,
        },{
            join => 'depend_on',
        })->next;
    }
    return $self->set_can_child;
}

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

has no_value_to_write => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
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

has topic_id => (
    is     => 'rw',
    isa    => Maybe[Int],
    coerce => sub { $_[0] || undef }, # Account for empty string from form
);

has topic => (
    is => 'lazy',
);

sub _build_topic
{   my $self = shift;
    $self->topic_id or return;
    $self->schema->resultset('Topic')->find($self->topic_id);
}

has display_field => (
    is  => 'rw',
    isa => Maybe[Int],
);

has display_regex => (
    is  => 'rw',
    isa => Maybe[Str],
);

sub regex_b64
{   my $self = shift;
    return unless $self->display_regex;
    encode_base64 $self->display_regex, ''; # base64 plugin does not like new lines in content
}

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
    clearer => 1,
);

has retrieve_fields => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_retrieve_fields
{   my $self = shift;
    [$self->value_field];
}

has sort_field => (
    is => 'lazy',
);

sub _build_sort_field
{   shift->value_field;
}

# Used when searching for a value's index value as opposed to string value
# (e.g. enums)
sub value_field_as_index
{   my $self = shift;
    return $self->value_field;
}

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
            serial    => 'GADS::Datum::Serial',
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
            autocur   => 'GADS::Datum::Autocur',
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

has _rset => (
    is      => 'rwp',
    lazy    => 1,
    builder => 1,
);

sub _build__rset
{   my $self = shift;
    $self->id or return;
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

# Return a human-readable summary of groups that have a particular permission
sub group_summary
{   my ($self, $permission) = @_;

    my $groups = GADS::Groups->new(
        schema => $self->schema,
    );

    # First get all group IDs that have this permission
    my @group_ids = map {
        (grep { $_->short eq $permission } @{$self->permissions->{$_}}) ? $_ : ();
    } keys %{$self->permissions};

    # Then turn it into readable format, annotating whether it requires
    # approval in the case of write permissions
    sort map {
        my $name = $groups->group($_)->name;
        $name .= ' (with approval only)'
            if $permission =~ /write/
                && ! grep { $_->short eq "${permission}_no_approval" } @{$self->permissions->{$_}};
        $name;
    } @group_ids;
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
    $self->topic_id($original->{topic_id});
    $self->optional($original->{optional});
    $self->remember($original->{remember});
    $self->isunique($original->{isunique});
    $self->set_can_child($original->{can_child});
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

    # XXX Move to curval class
    if ($self->type eq 'curval')
    {
        $self->set_filter($original->{filter});
        $self->multivalue(1) if $self->show_add && $self->value_selector eq 'noshow';
    }

}

# Overriden for most columns
sub tjoin
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
        join     => 'layout',
        # Order by values so that multiple values appear in consistent order as
        # field values
        order_by => "me.".$self->value_field,
    };
    if (ref $self->tjoin)
    {
        my ($left, $prefetch) = %{$self->tjoin}; # Prefetch table is 2nd part of join
        $select->{prefetch} = $prefetch;
        # Override previous setting
        $select->{order_by} = "$prefetch.".$self->value_field;
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
        my @pn = map { $_->parent->name." (".$_->parent->instance->name.")" } @parents;
        my $p  = join ', ', @pn;
        error __x"The following fields in another table refer to this field: {p}.
            Please remove these references before deletion of this field.", p => $p;
    }

    # Now see if any linked fields depend on this one
    if (my @linked = $self->schema->resultset('Layout')->search({
            link_parent => $self->id
        })->all
    )
    {
        my @ln = map { $_->name." (".$_->instance->name.")"; } @linked;
        my $l  = join ', ', @ln;
        error __x"The following fields in another table are linked to this field: {l}.
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
    foreach my $type (grep { $_ ne 'serial' } $self->types)
    {
        my $class = "GADS::Column::".camelize $type;
        $class->cleanup($self->schema, $self->id);
    }

    $self->schema->resultset('ViewLayout')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('Filter')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('AlertCache')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('AlertSend')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('Sort')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('Sort')->search({ parent_id => $self->id })->delete;
    $self->schema->resultset('LayoutDepend')->search({ layout_id => $self->id })->delete;
    $self->schema->resultset('LayoutGroup')->search({ layout_id => $self->id })->delete;

    $self->schema->resultset('Instance')->search({ sort_layout_id => $self->id })->update({sort_layout_id => undef});;
    $self->schema->resultset('Layout')->find($self->id)->delete;

    $guard->commit;
}

sub write_special { () } # Overridden in children
sub after_write_special {} # Overridden in children

sub write
{   my ($self, %options) = @_;

    error __"You do not have permission to manage fields"
        unless $self->layout->user_can("layout");

    my $guard = $self->schema->txn_scope_guard;

    my $newitem;
    $newitem->{name} = $self->name
        or error __"Please enter a name for item";
    grep { $_->{name} eq $newitem->{name} } @{$self->layout->internal_columns}
        and error __x"{name} is a reserved name for a field", name => $newitem->{name};
    $newitem->{type} = $self->type
        or error __"Please select a type for the item";
    $self->display_field && $self->display_field == $self->id
        and error __"Display condition field cannot be the same as the field itself";

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

    $newitem->{topic_id}      = $self->topic_id;
    $newitem->{optional}      = $self->optional;
    $newitem->{remember}      = $self->remember;
    $newitem->{isunique}      = $self->isunique;
    $newitem->{can_child}     = $self->set_can_child if $self->has_set_can_child;
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

    unless ($options{report_only})
    {
        if (!$self->id)
        {
            $newitem->{id} = $self->set_id if $self->set_id;
            # Add at end of other items
            $newitem->{position} = ($self->schema->resultset('Layout')->get_column('position')->max || 0) + 1
                unless $self->position;
            $rset = $self->schema->resultset('Layout')->create($newitem);
            $new_id = $rset->id;
            $self->_set__rset($rset);
            # Don't set $self->id here, as we could yet bail out and the object
            # would be left with an id, which would signify it is not a new field
            # (affects display of type when creating field)
        }
        else {
            if ($rset = $self->schema->resultset('Layout')->find($self->id))
            {
                # Check whether attempt to move between instances - this is a bug
                $newitem->{instance_id} != $rset->instance_id
                    and panic "Attempt to move column between instances";
                $rset->update($newitem);
            }
            else {
                $newitem->{id} = $self->id;
                $rset = $self->schema->resultset('Layout')->create($newitem);
                $self->_set__rset($rset);
            }
        }

        # Write any column-specific params
        my %write_options = $self->write_special(rset => $rset, id => $new_id || $self->id, %options);
        %options = (%options, %write_options);
    }

    $self->_write_permissions(id => $new_id || $self->id, %options);

    $guard->commit;

    return if $options{report_only};

    if ($new_id || $options{add_db})
    {
        $self->id($new_id) if $new_id;
        unless ($options{no_db_add})
        {
            GADS::DB->add_column($self->schema, $self);
            # Ensure new column is properly added to layout
            $self->layout->clear;
        }
    }
    $self->after_write_special(%options);

    $self->layout->clear_indexes;
}

sub user_can
{   my ($self, $permission) = @_;
    return 1 if $self->user_permission_override;
    return 1 if $self->internal && $permission eq 'read';
    return 0 if !$self->userinput && $permission ne 'read'; # Can't write to code fields
    return 1 if $self->layout->current_user_can_column($self->id, $permission);
    if ($permission eq 'write') # shortcut
    {
        return 1
            if $self->layout->current_user_can_column($self->id, 'write_new')
            || $self->layout->current_user_can_column($self->id, 'write_existing');
    }
    0;
}

# Whether a particular user ID has a permission for this column
sub user_id_can
{   my ($self, $user_id, $permission) = @_;
    return $self->layout->user_can_column($user_id, $self->id, $permission)
}

has set_permissions => (
    is        => 'rw',
    isa       => HashRef,
    predicate => 1,
);

sub _write_permissions
{   my ($self, %options) = @_;

    my $id = $options{id} || $self->id;

    $self->has_set_permissions or return;

    my %permissions = %{$self->set_permissions};

    my @groups = keys %permissions;

    # Search for any groups that were in the permissions but no longer exist.
    # Add these to the set_permissions hash, so they get processed and removed
    # as per other permissions (in particular ensuring the read_removed flag is
    # set)
    my $search = {
        layout_id => $id,
    };

    $search->{group_id} = { '!=' => [ '-and', @groups ] }
        if @groups;
        
    my @removed = $self->schema->resultset('LayoutGroup')->search($search,{
        select   => {
            max => 'group_id',
            -as => 'group_id',
        },
        as       => 'group_id',
        group_by => 'group_id',
    })->get_column('group_id')->all;

    $permissions{$_} = []
        foreach @removed;
    @groups = keys %permissions; # Refresh

    foreach my $group_id (@groups)
    {
        my @new_permissions = @{$permissions{$group_id}};

        my @existing_permissions = $self->schema->resultset('LayoutGroup')->search({
            layout_id  => $id,
            group_id   => $group_id,
        })->get_column('permission')->all;

        my $lc = List::Compare->new(\@new_permissions, \@existing_permissions);

        my @removed_permissions = $lc->get_complement();
        my @added_permissions   = $lc->get_unique();

        # Has a read permission been removed from this group?
        my $read_removed = grep { $_ eq 'read' } @removed_permissions;

        # Delete any permissions no longer needed
        if ($options{report_only} && @removed_permissions)
        {
            notice __x"Removing the following permissions from {column} for group ID {group}: {perms}",
                column => $self->name, group => $group_id, perms => join(', ', @removed_permissions);
        }
        else {
            $self->schema->resultset('LayoutGroup')->search({
                layout_id  => $id,
                group_id   => $group_id,
                permission => \@removed_permissions
            })->delete;
        }

        # Add any new permissions
        if ($options{report_only} && @added_permissions)
        {
            notice __x"Adding the following permissions to {column} for group ID {group}: {perms}",
                column => $self->name, group => $group_id, perms => join(', ', @added_permissions);
        }
        else {
            $self->schema->resultset('LayoutGroup')->create({
                layout_id  => $id,
                group_id   => $group_id,
                permission => $_,
            }) foreach @added_permissions;
        }

        if ($read_removed && !$options{report_only}) {
            # First the sorts
            my @sorts = $self->schema->resultset('Sort')->search({
                layout_id      => $id,
                'view.user_id' => { '!=' => undef },
            }, {
                prefetch => 'view',
            })->all;

            foreach my $sort (@sorts) {
                # For each sort on this column, which no longer has read.
                # See if user attached to this view still has access with
                # another group
                $sort->delete unless $self->user_id_can($sort->view->user_id, 'read');
            }

            # Then the filters
            my @filters = $self->schema->resultset('Filter')->search({
                layout_id      => $id,
                'view.user_id' => { '!=' => undef },
            }, {
                prefetch => 'view',
            })->all;

            foreach my $filter (@filters) {
                # For each sort on this column, which no longer has read.
                # See if user attached to this view still has access with
                # another group

                next if $self->user_id_can($filter->view->user_id, 'read');

                # Filter cache
                $filter->delete;

                # Alert cache
                $self->schema->resultset('AlertCache')->search({
                    layout_id => $id,
                    view_id   => $filter->view_id,
                })->delete;

                # Column in the view
                $self->schema->resultset('ViewLayout')->search({
                    layout_id => $id,
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

sub import_hash
{   my ($self, $values, %options) = @_;
    my $report = $options{report_only} && $self->id;
    notice __x"Update: name from {old} to {new}", old => $self->name, new => $values->{name}
        if $report && $self->name ne $values->{name};
    $self->name($values->{name});
    notice __x"Update: name_short from {old} to {new}", old => $self->name_short, new => $values->{name_short}
        if $report && ($self->name_short || '') ne ($values->{name_short} || '');
    $self->name_short($values->{name_short});
    notice __x"Update: optional from {old} to {new}", old => $self->optional, new => $values->{optional}
        if $report && $self->optional != $values->{optional};
    $self->optional($values->{optional});
    notice __x"Update: remember from {old} to {new}", old => $self->remember, new => $values->{remember}
        if $report && $self->remember != $values->{remember};
    $self->remember($values->{remember});
    notice __x"Update: isunique from {old} to {new}", old => $self->isunique, new => $values->{isunique}
        if $report && $self->isunique != $values->{isunique};
    $self->isunique($values->{isunique});
    notice __x"Update: can_child from {old} to {new}", old => $self->can_child, new => $values->{can_child}
        if $report && $self->can_child != $values->{can_child};
    $self->set_can_child($values->{can_child});
    notice __x"Update: position from {old} to {new}", old => $self->position, new => $values->{position}
        if $report && $self->position != $values->{position};
    $self->position($values->{position});
    notice __x"Update: description from {old} to {new}", old => $self->description, new => $values->{description}
        if $report && $self->description ne $values->{description};
    $self->description($values->{description});
    notice __x"Update: helptext from {old} chars to {new} chars", old => length($self->helptext), new => length($values->{helptext})
        if $report && $self->helptext ne $values->{helptext};
    $self->helptext($values->{helptext});
    notice __x"Update: display_regex from {old} to {new}", old => $self->display_regex, new => $values->{display_regex}
        if $report && ($self->display_regex || '') ne ($values->{display_regex} || '');
    $self->display_regex($values->{display_regex});
    notice __x"Update: multivalue from {old} to {new}", old => $self->multivalue, new => $values->{multivalue}
        if $report && $self->multivalue != $values->{multivalue};
    $self->multivalue($values->{multivalue});
    notice __x"Update: filter from {old} to {new}", old => $self->filter->as_json, new => $values->{filter}
        if $report && $self->filter->as_json ne $values->{filter};
    $self->filter(GADS::Filter->new(as_json => $values->{filter}));
    foreach my $option (@{$self->option_names})
    {
        notice __x"Update: {option} from {old} to {new}",
            option => $option, old => $self->$option, new => $values->{filter}
            if $report && $self->$option ne $values->{$option};
        $self->$option($values->{$option});
    }
}

sub export_hash
{   my $self = shift;
    my $permissions;
    foreach my $perm ($self->schema->resultset('LayoutGroup')->search({ layout_id => $self->id })->all)
    {
        $permissions->{$perm->group_id} ||= [];
        push @{$permissions->{$perm->group_id}}, $perm->permission;
    }
    my $return = {
        id            => $self->id,
        type          => $self->type,
        name          => $self->name,
        name_short    => $self->name_short,
        topic_id      => $self->topic_id,
        optional      => $self->optional,
        remember      => $self->remember,
        isunique      => $self->isunique,
        can_child     => $self->can_child,
        position      => $self->position,
        description   => $self->description,
        helptext      => $self->helptext,
        display_field => $self->display_field,
        display_regex => $self->display_regex,
        link_parent   => $self->link_parent && $self->link_parent->id,
        multivalue    => $self->multivalue,
        filter        => $self->filter->as_json,
        permissions   => $permissions,
    };
    foreach my $option (@{$self->option_names})
    {
        $return->{$option} = $self->$option;
    }
    return $return;
}

# Subroutine to run after a column write has taken place for an import
sub import_after_write {};

# Subroutine to run after all columns have been imported
sub import_after_all
{   my ($self, $values, %options) = @_;
    my $mapping = $options{mapping};
    my $report  = $options{report_only};
    if ($values->{display_field})
    {
        my $new_id = $mapping->{$values->{display_field}};
        notice __x"Update: display_field from {old} to {new}", old => $self->display_field, new => $new_id
            if $report && ($self->display_field || 0) != ($new_id || 0);
        $self->display_field($new_id);
    }
    if ($values->{link_parent})
    {
        my $new_id = $mapping->{$values->{link_parent}};
        notice __x"Update: link_parent from {old} to {new}", old => $self->link_parent, new => $new_id
            if $report && ($self->link_parent || 0) != ($new_id || 0);
        $self->link_parent($new_id);
    }
}

1;

