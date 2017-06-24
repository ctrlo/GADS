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
    is => 'lazy',
);

has user_count => (
    is      => 'ro',
    isa     => Int,
    default => 1,
);

has no_groups => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has user => (
    is => 'lazy',
);

sub _build_user
{   my $self = shift;
    my $user;
    for my $id (1..$self->user_count)
    {
        my $user_rs = $self->schema->resultset('User')->find_or_create({ # May already be created for schema
            id        => $id,
            username  => "user$id\@example.com",
            email     => "user$id\@example.com",
            firstname => "User$id",
            surname   => "User$id",
            value     => "User$id, User$id",
        });
        $self->schema->resultset('UserGroup')->find_or_create({ # May already be created for schema
            user_id  => $id,
            group_id => $self->group->id,
        });
        # Most of the app expects a hash at the moment. XXX Need to convert to object
        # Just return first one for use in tests by default
        $user ||= {
            id        => $user_rs->id,
            firstname => $user_rs->firstname,
            surname   => $user_rs->surname,
            email     => $user_rs->email,
            value     => $user_rs->value,
        };
    }
    return $user;
}

has group => (
    is => 'lazy',
);

has columns => (
    is      => 'ro',
    lazy    => 1,
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

has records => (
    is => 'lazy',
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
    is      => 'ro',
    default => 0,
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
        user                     => undef,
        schema                   => $self->schema,
        config                   => $self->config,
        instance_id              => $self->instance_id,
        user_permission_override => 1,
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
    my $permissions = [qw/read/];

    my $columns = {};

    my $string1 = GADS::Column::String->new(
        schema => $schema,
        user   => undef,
        layout => $layout,
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
        schema => $schema,
        user   => undef,
        layout => $layout,
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
            schema => $schema,
            user   => undef,
            layout => $layout,
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
        schema => $schema,
        user   => undef,
        layout => $layout,
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
        schema => $schema,
        user   => undef,
        layout => $layout,
    );
    $tree1->from_id($tree_id);
    $tree1->set_permissions(permissions => {$self->group->id => $permissions})
        unless $self->no_groups;

    my $date1 = GADS::Column::Date->new(
        schema => $schema,
        user   => undef,
        layout => $layout,
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
        schema => $schema,
        user   => undef,
        layout => $layout,
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
        schema => $schema,
        user   => undef,
        layout => $layout,
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
        schema => $schema,
        user   => undef,
        layout => $layout,
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
        $record->fields->{$columns->{"enum$_"}->id}->set_value($datum->{"enum$_"})
            foreach 1..$self->column_count->{enum};
        $record->fields->{$columns->{tree1}->id}->set_value($datum->{tree1});
        $record->fields->{$columns->{date1}->id}->set_value($datum->{date1});
        $record->fields->{$columns->{daterange1}->id}->set_value($datum->{daterange1});
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

        try { $record->write(no_alerts => 1) } hide => 'ALL';
        $@->reportAll(is_fatal => 0);
        $@ and return;
    }
    1;
};

1;

