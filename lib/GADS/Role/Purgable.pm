package GADS::Role::Purgable;

use strict;
use warnings;

use Moo::Role;

has valuefield => (
    is      => 'lazy',
    builder => sub { ('value'); }
);

sub purge {
    my ($self,$user) = @_;
    
    my @field = $self->valuefield or error __"No valuefield defined";
    my $schema = $self->result_source->schema;

    $schema->txn_do(sub {
        $self->update({ $_ => undef }) foreach @field;
        $self->update({ purged_by => $user, purged_on => DateTime->now() });
    });
}

1;