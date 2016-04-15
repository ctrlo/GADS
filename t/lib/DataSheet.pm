package t::lib::DataSheet;

use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Schema;
use Moo;

has data => (
    is      => 'rw',
    default => sub {
        [
            {
                string1    => 'Foo',
                date1      => '2014-10-10',
                daterange1 => ['2012-02-10', '2013-06-15'],
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
    is => 'lazy',
);

has columns => (
    is => 'lazy',
);

has records => (
    is => 'lazy',
);

sub _build_schema
{   my $self = shift;
    my $schema = GADS::Schema->connect({ dsn => 'dbi:SQLite:dbname=:memory:', quote_names => 1 });
    $schema->deploy;
    $schema;
}

sub _build_layout
{   my $self = shift;

    $self->schema->resultset('Instance')->create({
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

sub _build_columns
{   my $self = shift;

    my $schema = $self->schema;
    my $layout = $self->layout;

    my $columns = {};

    my $string1 = GADS::Column::String->new(
        schema => $schema,
        user   => undef,
        layout => $layout,
    );
    $string1->type('string');
    $string1->name('String1');
    try { $string1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }

    my $integer1 = GADS::Column::Intgr->new(
        schema => $schema,
        user   => undef,
        layout => $layout,
    );
    $integer1->type('intgr');
    $integer1->name('Integer1');
    try { $integer1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }

    my $enum1 = GADS::Column::Enum->new(
        schema => $schema,
        user   => undef,
        layout => $layout,
    );
    $enum1->type('enum');
    $enum1->name('Enum1');
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

    my $tree1 = GADS::Column::Tree->new(
        schema => $schema,
        user   => undef,
        layout => $layout,
    );
    $tree1->type('tree');
    $tree1->name('Tree1');
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
        'id' => 'j1_1'
    },
    {
        'data' => {},
        'text' => 'tree2',
        'children' => [],
        'id' => 'j1_2'
    },
    {
        'data' => {},
        'text' => 'tree3',
        'children' => [],
        'id' => 'j1_2'
    }]);
    # Reload to get tree built etc
    $tree1 = GADS::Column::Tree->new(
        schema => $schema,
        user   => undef,
        layout => $layout,
    );
    $tree1->from_id($tree_id);

    my $date1 = GADS::Column::Date->new(
        schema => $schema,
        user   => undef,
        layout => $layout,
    );
    $date1->type('date');
    $date1->name('Date1');
    try { $date1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }

    my $daterange1 = GADS::Column::Daterange->new(
        schema => $schema,
        user   => undef,
        layout => $layout,
    );
    $daterange1->type('daterange');
    $daterange1->name('Daterange1');
    try { $daterange1->write };
    if ($@)
    {
        $@->wasFatal->throw(is_fatal => 0);
        return;
    }

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
        try { $record->write(no_alerts => 1) };
        $@ and return;
    }
    1;
};

1;

