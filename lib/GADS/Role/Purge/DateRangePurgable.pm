package GADS::Role::Purge::DateRangePurgable;

use strict;
use warnings;

use Moo::Role;

with 'GADS::Role::Purgeable';

sub purge {
    my $self = shift;

    my $schema = $self->result_source->schema;

    $schema->txn_do(sub {
        $self->update({
            to   => undef,
            from => undef,
        });
    });
}

1;