package GADS::Role::Purgeable;

use strict;
use warnings;

use Moo::Role;

has recordsource => (
    is      => 'lazy',
    builder => sub {undef},
);

has valuefield => (
    is      => 'lazy',
    builder => sub {undef},
);

sub purge {
    my $self = shift;

    my $source = $self->recordsource or die "recordsource is required";
    my $field = $self->valuefield or die "valuefield is required";
    my $schema = $self->result_source->schema;

    $schema->txn_do(sub {
        $schema->resultset($source)->update({ $field => undef });
    });
}

1;