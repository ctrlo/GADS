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

has data => (
    is      => 'rw',
    default => sub {
        [
            {
                string1    => 'Foo',
                integer1   => 50,
                date1      => '2014-10-10',
                daterange1 => ['2012-02-10', '2013-06-15'],
            },
            {
                string1    => 'Bar',
                integer1   => 99,
                date1      => '2009-01-02',
                daterange1 => ['2008-05-04', '2008-07-14'],
            },
        ];
    },
);

has schema => (
    is => 'lazy',
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

has group => (
    is => 'lazy',
);

has columns => (
    is => 'lazy',
);

has records => (
    is => 'lazy',
);

has curval => (
    is => 'ro',
);

sub _build_schema
{   my $self = shift;
    my $schema = GADS::Schema->connect({
        dsn             => 'dbi:SQLite:dbname=:memory:',
        on_connect_call => 'use_foreign_keys',
        quote_names     => 1,
    });
    $schema->deploy;
    $schema;
}

sub _build_layout
{   my $self = shift;

    $self->schema->resultset('Instance')->find_or_create({
        id   => $self->instance_id,
        name => 'Layout'.$self->instance_id,
    });

    GADS::Layout->new(
        user                     => undef,
        schema                   => $self->schema,
        config                   => undef,
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

sub _build_columns
{   my $self = shift;

    my $schema      = $self->schema;
    my $layout      = $self->layout;
    my $permissions = [qw/read/];

    my $columns = {};

    my $string1 = GADS::Column::String->new(
        schema => $schema,
        user   => undef,
        layout => $layout,
    );
    $string1->type('string');
    $string1->name('string1');
    try { $string1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }
    $string1->set_permissions($self->group->id, $permissions)
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
    $integer1->set_permissions($self->group->id, $permissions)
        unless $self->no_groups;

    my $enum1 = GADS::Column::Enum->new(
        schema => $schema,
        user   => undef,
        layout => $layout,
    );
    $enum1->type('enum');
    $enum1->name('enum1');
    $enum1->enumvals([
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
    try { $enum1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }
    $enum1->set_permissions($self->group->id, $permissions)
        unless $self->no_groups;

    my $tree1 = GADS::Column::Tree->new(
        schema => $schema,
        user   => undef,
        layout => $layout,
    );
    $tree1->type('tree');
    $tree1->name('tree1');
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
    $tree1->set_permissions($self->group->id, $permissions)
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
    $date1->set_permissions($self->group->id, $permissions)
        unless $self->no_groups;

    my $daterange1 = GADS::Column::Daterange->new(
        schema => $schema,
        user   => undef,
        layout => $layout,
    );
    $daterange1->type('daterange');
    $daterange1->name('daterange1');
    try { $daterange1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }
    $daterange1->set_permissions($self->group->id, $permissions)
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
    $file1->set_permissions($self->group->id, $permissions)
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
    $person1->set_permissions($self->group->id, $permissions)
        unless $self->no_groups;

    my $curval1;
    if ($self->curval)
    {
        GADS::Config->instance(
            config => undef,
        );
        $curval1 = GADS::Column::Curval->new(
            schema => $self->schema,
            user   => undef,
            layout => $self->layout,
        );
        my $refers_to_instance = $self->curval;
        $curval1->refers_to_instance($refers_to_instance);
        my $curval_field_ids_rs = $self->schema->resultset('Layout')->search({
            instance_id => $refers_to_instance,
        });
        my @curval_field_ids = map { $_->id } $curval_field_ids_rs->all;
        $curval1->curval_field_ids([@curval_field_ids]);
        $curval1->type('curval');
        $curval1->name('curval1');
        try { $curval1->write };
        if ($@)
        {
            $@->wasFatal->throw(is_fatal => 0);
            return;
        }
        $curval1->set_permissions($self->group->id, $permissions)
            unless $self->no_groups;
    }

    my $rag1 = GADS::Column::Rag->new(
        schema => $schema,
        user   => undef,
        layout => $layout,
    );
    $rag1->red  ('[Daterange1.from.year] < 2012');
    $rag1->amber('[Daterange1.from.year] == 2012');
    $rag1->green('[Daterange1.from.year] > 2012');
    $rag1->type('rag');
    $rag1->name('rag1');
    try { $rag1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }
    $rag1->set_permissions($self->group->id, $permissions)
        unless $self->no_groups;
    $self->clear_layout;
    $layout = $self->layout;
    my $calc1 = GADS::Column::Calc->new(
        schema => $schema,
        user   => undef,
        layout => $layout,
    );
    $calc1->calc('[Daterange1.from.year]');
    $calc1->type('calc');
    $calc1->name('calc1');
    $calc1->return_type('integer');
    try { $calc1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }
    $calc1->set_permissions($self->group->id, $permissions)
        unless $self->no_groups;


    # Only add the columns now to the columns hash, as this will lazily build
    # the columns index in the layout, which would otherwise be incomplete.
    # We return the reference to the layout one, in case we change any of
    # the objects properties, which are used by the datums.
    $columns->{string1}    = $layout->column($string1->id);
    $columns->{integer1}   = $layout->column($integer1->id);
    $columns->{enum1}      = $layout->column($enum1->id);
    $columns->{tree1}      = $layout->column($tree1->id);
    $columns->{date1}      = $layout->column($date1->id);
    $columns->{daterange1} = $layout->column($daterange1->id);
    $columns->{curval1}    = $layout->column($curval1->id)
        if $curval1;
    $columns->{calc1}      = $layout->column($calc1->id);
    $columns->{rag1}       = $layout->column($rag1->id);
    $columns->{file1}      = $layout->column($file1->id);
    $columns->{person1}    = $layout->column($person1->id);
    $columns;
}

sub create_records
{   my $self = shift;

    my $record = GADS::Record->new(
        user     => undef,
        layout   => $self->layout,
        schema   => $self->schema,
        base_url => undef,
    );

    my $columns = $self->columns;

    foreach my $datum (@{$self->data})
    {
        $record->clear;
        $record->initialise;
        $record->fields->{$columns->{string1}->id}->set_value($datum->{string1});
        $record->fields->{$columns->{integer1}->id}->set_value($datum->{integer1});
        $record->fields->{$columns->{enum1}->id}->set_value($datum->{enum1});
        $record->fields->{$columns->{tree1}->id}->set_value($datum->{tree1});
        $record->fields->{$columns->{date1}->id}->set_value($datum->{date1});
        $record->fields->{$columns->{daterange1}->id}->set_value($datum->{daterange1});
        # Create users on the fly as required
        if ($datum->{person1} && !$self->schema->resultset('User')->find($datum->{person1}))
        {
            my $user_id = $datum->{person1};
            $self->schema->resultset('User')->find_or_create({
                id       => $user_id,
                username => "user$user_id\@example.com",
                email    => "user$user_id\@example.com",
                value    => ', ',
            });
            $columns->{person1}->clear_people;
        }
        $record->fields->{$columns->{person1}->id}->set_value($datum->{person1});
        $record->fields->{$columns->{curval1}->id}->set_value($datum->{curval1})
            if $columns->{curval1};
        # Only set file data if exists in data. Add random data if nothing specified

        if (exists $datum->{file1})
        {
            my $file = $datum->{file1};
            if (!$file)
            {
                $file = {
                    name     => 'myfile.txt',
                    mimetype => 'text/plain',
                    content  => 'My text file',
                };
            }
            $record->fields->{$columns->{file1}->id}->set_value($file);
        }

        try { $record->write(no_alerts => 1) };
        $@ and return;
    }
    1;
};

1;

