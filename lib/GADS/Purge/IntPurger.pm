package GADS::Purge::IntPurger;

use strict;
use warnings;

use feature 'say';

use Moo;

extends 'GADS::Purge::RecordPurger';

has record => (
    is       => 'ro',
    required => 1,
);

has layout_id => (
    is       => 'ro',
    required => 1,
);

has schema => (
    is       => 'ro',
    required => 1,
);

has record_id => (
    is       => 'ro',
    required => 0,
);

sub purge {
    my $self = shift;

    my $schema = $self->schema or die "Invalid schema or schema not defined";

    my @intgrs = $self->record->intgrs;
    for my $intgr (@intgrs) {
        next if $intgr->layout_id != $self->layout_id;
        $schema->txn_do(sub {
            $intgr->update({ value => undef });
        });
    }
}

1;