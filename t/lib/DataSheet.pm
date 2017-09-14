package t::lib::DataSheet;

use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Group;
use GADS::Layout;
use GADS::Record;
use GADS::Schema;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

sub clear_not_data
{   my ($self, %options) = @_;
    foreach my $key (keys %options)
    {
        my $prop = "_set_$key";
        $self->$prop($options{$key});
    }

    $self->layout->purge;
    $self->clear_layout;
    $self->clear_columns;
    $self->create_records;
}

# Set up a config singleton. This will be updated as required
GADS::Config->instance(
    config => undef,
);

has data => (
    is      => 'lazy',
);

has curval_offset => (
   is  => 'lazy',
   isa => Int,
);

sub _build_curval_offset
{   my $self = shift;
    $self->curval ? 6 : 0;
}

sub _build_data
{   my $self = shift;
    [
        {
            string1    => 'Foo',
            integer1   => 50,
            date1      => '2014-10-10',
            enum1      => 1 + $self->curval_offset,
            daterange1 => ['2012-02-10', '2013-06-15'],
        },
        {
            string1    => 'Bar',
            integer1   => 99,
            date1      => '2009-01-02',
            enum1      => 2 + $self->curval_offset,
            daterange1 => ['2008-05-04', '2008-07-14'],
        },
    ];
}

has schema => (
    is => 'lazy',
);

has site_id => (
    is      => 'ro',
);

has instance_id => (
    is      => 'ro',
    default => 1,
);

has layout => (
    is      => 'lazy',
    clearer => 1,
);

has no_groups => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has user => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_user
{   my $self = shift;
    $self->_users->{superadmin};
}

# The user used to build the layout - will normally be superadmin
has user_layout => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->user },
);

has user_normal1 => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_user_normal1
{   my $self = shift;
    $self->_users->{normal1};
}

has user_normal2 => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_user_normal2
{   my $self = shift;
    $self->_users->{normal2};
}

has _users => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build__users
{   my $self = shift;
    # If the site_id is defined, then we may be cresating multiple sites.
    # Therefore, offset the ID with the number of sites, to account that the
    # row IDs may already have been used.  This assumes that when testing
    # multiple sites that only the default 5 users are created.
    my $return; my $count = $self->schema->site_id && ($self->schema->site_id - 1) * 5;
    foreach my $permission (qw/superadmin audit useradmin normal1 normal2/)
    {
        $count++;
        my $perms = $permission =~ 'normal' ? [] : [$permission];
        $return->{$permission} = $self->create_user(permissions => $perms, user_id => $count);
    }
    $return;
}

sub create_user
{   my ($self, %options) = @_;
    my @permissions = @{$options{permissions} || []};
    my $instance_id = $options{instance_id} || $self->instance_id;
    my $user_id     = $options{user_id};

    my $user_rs = $user_id
        ? $self->schema->resultset('User')->find_or_create({ id => $user_id })
        : $self->schema->resultset('User')->create({});
    $user_id ||= $user_rs->id;
    $user_rs->update({
        username  => "user$user_id\@example.com",
        email     => "user$user_id\@example.com",
        firstname => "User$user_id",
        surname   => "User$user_id",
        value     => "User$user_id, User$user_id",
    });
    $self->schema->resultset('UserGroup')->find_or_create({ # May already be created for schema
        user_id  => $user_id,
        group_id => $self->group->id,
    }) if $self->group;
    # Most of the app expects a hash at the moment. XXX Need to convert to object
    # Just return first one for use in tests by default
    my $user = {
        id         => $user_rs->id,
        firstname  => $user_rs->firstname,
        surname    => $user_rs->surname,
        email      => $user_rs->email,
        value      => $user_rs->value,
    };
    foreach my $permission (@permissions)
    {
        if (my $permission_id = $self->_permissions->{$permission})
        {
            $self->schema->resultset('UserPermission')->find_or_create({
                user_id       => $user_id,
                permission_id => $permission_id,
            });
            $user->{permission} = {
                $permission => 1,
            },
        }
        else {
            # Create a group for each user/permission
            my $group = $self->schema->resultset('Group')->create({
                name => "${permission}_$user_id",
            });
            $self->schema->resultset('InstanceGroup')->find_or_create({
                instance_id => $instance_id,
                group_id    => $group->id,
                permission  => $permission,
            });
            $self->schema->resultset('UserGroup')->find_or_create({
                user_id  => $user_id,
                group_id => $group->id,
            });
        }
    }
    return $user;
}

has _permissions => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build__permissions
{   my $self = shift;
    my $return;
    foreach my $permission (qw/superadmin audit useradmin/)
    {
        my $existing = $self->schema->resultset('Permission')->search({
            name => $permission,
        })->next;
        my $id = $existing ? $existing->id : $self->schema->resultset('Permission')->create({
            name => $permission,
        })->id;
        $return->{$permission} = $id;
    }
    $return;
}

has group => (
    is      => 'lazy',
    clearer => 1,
);

has columns => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        my $columns = $self->__build_columns
            # Errors should have been caught and reported during _build_columns
            or error "Failed to build columns. Check previous messages for details of errors";
        return $columns;
    },
);

# Whether to create multiple columns of a particular type
has column_count => (
    is      => 'ro',
    default => sub {
        +{
            enum   => 1,
            curval => 1,
        }
    },
);

has curval => (
    is => 'ro',
);

has curval_field_ids => (
    is => 'ro',
);

has calc_code => (
    is  => 'lazy',
    isa => Str,
);

sub _build_calc_code
{   my $self = shift;
    my $instance_id = $self->instance_id;
    "function evaluate (L${instance_id}daterange1) \n if L${instance_id}daterange1 == null then return end \n return L${instance_id}daterange1.from.year\nend";
}

has calc_return_type => (
    is      => 'ro',
    isa     => Str,
    default => 'integer',
);

has multivalue => (
    is      => 'rwp',
    default => 0,
);

# Whether columns should be optional
has optional => (
    is      => 'ro',
    default => 1,
);

has user_permission_override => (
    is      => 'ro',
    default => 1,
);

has config => (
    is => 'lazy',
);

sub _build_config
{   my $self = shift;
    GADS::Config->instance;
}

sub _build_schema
{   my $self = shift;
    my $schema = GADS::Schema->connect({
        dsn             => 'dbi:SQLite:dbname=:memory:',
        on_connect_call => 'use_foreign_keys',
        quote_names     => 1,
    });
    $schema->deploy;
    if ($self->site_id)
    {
        $schema->resultset('Site')->create({
            id => $self->site_id,
        });
        $schema->site_id($self->site_id);
    }
    $schema;
}

sub _build_layout
{   my $self = shift;

    my $site_id = $self->schema->site_id;
    if ($site_id && !$self->schema->resultset('Site')->find($site_id))
    {
        $self->schema->resultset('Site')->create({
            id => $site_id,
        });
    }
    $self->schema->resultset('Instance')->find_or_create({
        id      => $self->instance_id,
        name    => 'Layout'.$self->instance_id,
        site_id => $self->schema->site_id,
    });

    GADS::Layout->new(
        user                     => $self->user_layout,
        schema                   => $self->schema,
        config                   => $self->config,
        instance_id              => $self->instance_id,
        user_permission_override => $self->user_permission_override,
    );
}

sub _build_group
{   my $self = shift;
    return if $self->no_groups;
    my $group  = GADS::Group->new(schema => $self->schema);
    $group->from_id;
    $group->name('group1');
    $group->write;
    $group;
}

# Exact name of _build_columns causes recursive loop in Moo...
sub __build_columns
{   my $self = shift;

    my $schema      = $self->schema;
    my $layout      = $self->layout;
    my $instance_id = $self->instance_id;
    my $permissions = [qw/read write_new write_existing write_new_no_approval write_existing_no_approval/];

    my $columns = {};

    my $string1 = GADS::Column::String->new(
        optional => $self->optional,
        schema   => $schema,
        user     => undef,
        layout   => $layout,
    );
    $string1->type('string');
    $string1->name('string1');
    $string1->name_short("L${instance_id}string1");
    try { $string1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }
    $string1->set_permissions(permissions => {$self->group->id => $permissions})
        unless $self->no_groups;

    my $integer1 = GADS::Column::Intgr->new(
        optional => $self->optional,
        schema   => $schema,
        user     => undef,
        layout   => $layout,
    );
    $integer1->type('intgr');
    $integer1->name('integer1');
    try { $integer1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }
    $integer1->set_permissions(permissions => {$self->group->id => $permissions})
        unless $self->no_groups;

    my @enums;
    foreach my $count (1..$self->column_count->{enum})
    {
        my $enum = GADS::Column::Enum->new(
            optional => $self->optional,
            schema   => $schema,
            user     => undef,
            layout   => $layout,
        );
        $enum->type('enum');
        $enum->name("enum$count");
        $enum->name_short("L${instance_id}enum$count");
        $enum->multivalue(1) if $self->multivalue;
        $enum->enumvals([
            {
                value => 'foo1',
            },
            {
                value => 'foo2',
            },
            {
                value => 'foo3',
            },
        ]);
        try { $enum->write };
        if ($@)
        {
            $@->wasFatal->throw(is_fatal => 0);
            return;
        }
        $enum->set_permissions(permissions => {$self->group->id => $permissions})
            unless $self->no_groups;
        push @enums, $enum;
    }

    my $tree1 = GADS::Column::Tree->new(
        optional => $self->optional,
        schema   => $schema,
        user     => undef,
        layout   => $layout,
    );
    $tree1->type('tree');
    $tree1->name('tree1');
    $tree1->name_short("L${instance_id}tree1");
    try { $tree1->write };
    my $tree_id = $tree1->id;
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }
    $tree1->update([{
        'children' => [],
        'data' => {},
        'text' => 'tree1',
        'id' => 'j1_1',
    },
    {
        'data' => {},
        'text' => 'tree2',
        'children' => [
            {
                'data' => {},
                'text' => 'tree3',
                'children' => [],
                'id' => 'j1_3'
            },
        ],
        'id' => 'j1_2',
    }]);
    # Reload to get tree built etc
    $tree1 = GADS::Column::Tree->new(
        optional => $self->optional,
        schema   => $schema,
        user     => undef,
        layout   => $layout,
    );
    $tree1->from_id($tree_id);
    $tree1->set_permissions(permissions => {$self->group->id => $permissions})
        unless $self->no_groups;

    my $date1 = GADS::Column::Date->new(
        optional => $self->optional,
        schema   => $schema,
        user     => undef,
        layout   => $layout,
    );
    $date1->type('date');
    $date1->name('date1');
    try { $date1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }
    $date1->set_permissions(permissions => {$self->group->id => $permissions})
        unless $self->no_groups;

    my $daterange1 = GADS::Column::Daterange->new(
        optional => $self->optional,
        schema   => $schema,
        user     => undef,
        layout   => $layout,
    );
    $daterange1->type('daterange');
    $daterange1->name('daterange1');
    $daterange1->name_short("L${instance_id}daterange1");
    try { $daterange1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }
    $daterange1->set_permissions(permissions => {$self->group->id => $permissions})
        unless $self->no_groups;

    my $file1 = GADS::Column::File->new(
        optional => $self->optional,
        schema   => $schema,
        user     => undef,
        layout   => $layout,
    );
    $file1->type('file');
    $file1->name('file1');
    try { $file1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }
    $file1->set_permissions(permissions => {$self->group->id => $permissions})
        unless $self->no_groups;

    my $person1 = GADS::Column::Person->new(
        optional => $self->optional,
        schema   => $schema,
        user     => undef,
        layout   => $layout,
    );
    $person1->type('person');
    $person1->name('person1');
    try { $person1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }
    $person1->set_permissions(permissions => {$self->group->id => $permissions})
        unless $self->no_groups;

    my @curvals;
    if ($self->curval)
    {
        foreach my $count (1..$self->column_count->{curval})
        {
            my $curval = GADS::Column::Curval->new(
                optional   => $self->optional,
                schema     => $self->schema,
                user       => undef,
                layout     => $self->layout,
                name_short => "L${instance_id}curval$count",
            );
            my $refers_to_instance = $self->curval;
            $curval->refers_to_instance($refers_to_instance);
            my $curval_field_ids_rs = $self->schema->resultset('Layout')->search({
                instance_id => $refers_to_instance,
            });
            my $curval_field_ids = $self->curval_field_ids || [ map { $_->id } $curval_field_ids_rs->all ];
            $curval->curval_field_ids($curval_field_ids);
            $curval->type('curval');
            $curval->name("curval$count");
            $curval->multivalue(1) if $self->multivalue;
            try { $curval->write };
            if ($@)
            {
                $@->wasFatal->throw(is_fatal => 0);
                return;
            }
            $curval->set_permissions(permissions => {$self->group->id => $permissions})
                unless $self->no_groups;
            push @curvals, $curval;
        }
    }

    my $rag1 = GADS::Column::Rag->new(
        schema => $schema,
        user   => undef,
        layout => $layout,
    );
    $rag1->code("
        function evaluate (L${instance_id}daterange1)
            if L${instance_id}daterange1 == nil then return end
            if L${instance_id}daterange1.from.year < 2012 then return 'red' end
            if L${instance_id}daterange1.from.year == 2012 then return 'amber' end
            if L${instance_id}daterange1.from.year > 2012 then return 'green' end
        end
    ");
    $rag1->type('rag');
    $rag1->name('rag1');
    try { $rag1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }
    $rag1->set_permissions(permissions => {$self->group->id => $permissions})
        unless $self->no_groups;

    # At this point, layout will have been built with current columns (it will
    # have been built as part of creating the RAG column). Therefore, clear it,
    # but keep the same reference in this object for code that has already taken
    # a reference to the old one.
    $self->layout->clear;

    my $calc1 = GADS::Column::Calc->new(
        schema => $schema,
        user   => undef,
        layout => $self->layout,
    );
    $calc1->code($self->calc_code);
    $calc1->type('calc');
    $calc1->name('calc1');
    $calc1->name_short("L${instance_id}calc1");
    $calc1->return_type($self->calc_return_type);
    try { $calc1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }
    $calc1->set_permissions(permissions => {$self->group->id => $permissions})
        unless $self->no_groups;

    # Clear the layout again, otherwise it won't include the calc
    # column itself (it will have been built as part of its creation)
    $self->layout->clear;

    # Only add the columns now to the columns hash, as this will lazily build
    # the columns index in the layout, which would otherwise be incomplete.
    # We return the reference to the layout one, in case we change any of
    # the objects properties, which are used by the datums.
    $columns->{string1}    = $layout->column($string1->id);
    $columns->{integer1}   = $layout->column($integer1->id);
    $columns->{$_->name}   = $layout->column($_->id)
        foreach (@enums, @curvals);
    $columns->{tree1}      = $layout->column($tree1->id);
    $columns->{date1}      = $layout->column($date1->id);
    $columns->{daterange1} = $layout->column($daterange1->id);
    $columns->{calc1}      = $layout->column($calc1->id);
    $columns->{rag1}       = $layout->column($rag1->id);
    $columns->{file1}      = $layout->column($file1->id);
    $columns->{person1}    = $layout->column($person1->id);
    $columns;
}

sub create_records
{   my $self = shift;

    my $columns = $self->columns;

    my $record = GADS::Record->new(
        user     => $self->user,
        layout   => $self->layout,
        schema   => $self->schema,
        base_url => undef,
    );

    foreach my $datum (@{$self->data})
    {
        $record->clear;
        $record->initialise;
        $record->fields->{$columns->{string1}->id}->set_value($datum->{string1});
        $record->fields->{$columns->{integer1}->id}->set_value($datum->{integer1});
        $record->fields->{$columns->{date1}->id}->set_value($datum->{date1});
        $record->fields->{$columns->{daterange1}->id}->set_value($datum->{daterange1});

        # Convert enums and trees from textual values if required
        foreach my $type (qw/enum tree/)
        {
            foreach my $count (1..($self->column_count->{$type} || 1))
            {
                my $v      = $datum->{"$type$count"};
                my @values = ref $v ? @$v : ($v);
                @values = map {
                    if ($_ && $_ !~ /^[0-9]+$/)
                    {
                        my $col = $columns->{"$type$count"}; # Same for enum and tree
                        my $in = $_;
                        my ($e) = grep { $_->{value} eq $in } @{$col->enumvals};
                        $e->{id};
                    }
                    else {
                        $_;
                    }
                } @values;
                $record->fields->{$columns->{"$type$count"}->id}->set_value([@values])
            }
        }

        # $record->fields->{$columns->{tree1}->id}->set_value($datum->{tree1});
        # Create users on the fly as required
        if ($datum->{person1} && !$self->schema->resultset('User')->find($datum->{person1}))
        {
            my $user_id = $datum->{person1};
            my $user = {
                id       => $user_id,
                username => "user$user_id\@example.com",
                email    => "user$user_id\@example.com",
                value    => "User$user_id, User$user_id",
            };
            $record->fields->{$columns->{person1}->id}->set_value($user);
        }
        $record->fields->{$columns->{person1}->id}->set_value($datum->{person1});
        if ($columns->{curval1})
        {
            $record->fields->{$columns->{"curval$_"}->id}->set_value($datum->{"curval$_"})
                foreach 1..$self->column_count->{curval};
        }
        # Only set file data if exists in data. Add random data if nothing specified

        if (exists $datum->{file1})
        {
            my $file = $datum->{file1};
            if (!defined $file)
            {
                $file = {
                    name     => 'myfile.txt',
                    mimetype => 'text/plain',
                    content  => 'My text file',
                };
            }
            $record->fields->{$columns->{file1}->id}->set_value($file);
        }

        $record->write(no_alerts => 1);
    }
    1;
};

# Convert a filter from column names to ids (as required to use)
sub convert_filter
{   my ($self, $filter) = @_;
    $filter or return;
    my %new_filter = %$filter; # Copy to prevent changing original
    $new_filter{rules} = []; # Make sure not using original ref in new
    foreach my $rule (@{$filter->{rules}})
    {
        next unless $rule->{name};
        # Copy again
        my %new_rule = %$rule;
        my @colnames = split /\_/, delete $new_rule{name};
        my @colids = map { /^[0-9]+/ ? $_ : $self->columns->{$_}->id } @colnames;
        $new_rule{id} = join '_', @colids;
        push @{$new_filter{rules}}, \%new_rule;
    }
    \%new_filter;
}

# Can be called during debugging to dump data table. Results to be expanded
# when required.
sub dump_data
{   my $self = shift;
    foreach my $current ($self->schema->resultset('Current')->search({
        instance_id => $self->layout->instance_id,
    })->all)
    {
        print $current->id.': ';
        my $record_id = $self->schema->resultset('Record')->search({
            current_id => $current->id
        })->get_column('id')->max;

        foreach my $ct (qw/tree1 enum1/)
        {
            my $v = $self->schema->resultset('Enum')->search({
                record_id => $record_id,
                layout_id => $self->columns->{$ct}->id,
            })->next;
            my $val = $v->value && $v->value->value || '';
            print "$ct ($val) ";
        }
        print "\n";
    }
}

1;

