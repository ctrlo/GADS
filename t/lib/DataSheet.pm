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
    $columns->{string1} = $string1;

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
    $columns->{date1} = $date1;

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
    $columns->{daterange1} = $daterange1;

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
        $record->fields->{$columns->{date1}->id}->set_value($datum->{date1});
        $record->fields->{$columns->{daterange1}->id}->set_value($datum->{daterange1});
        try { $record->write(no_alerts => 1) };
        $@ and return;
    }
    1;
};

1;

