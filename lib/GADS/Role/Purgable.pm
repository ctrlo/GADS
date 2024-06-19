package GADS::Role::Purgable;

use strict;
use warnings;

use Moo::Role;

has recordsource => (
    is      => 'lazy',
    builder => sub { undef; }
);

has valuefield => (
    is      => 'lazy',
    builder => sub { ('value'); }
);

sub purge {
    my $self = shift;
    
    my @field = $self->valuefield or error __"No valuefield defined";
    my $schema = $self->result_source->schema;

    $schema->txn_do(sub {
        $self->update({ $_ => undef}) foreach @field;
    });
}

1;