package GADS::Purge::EnumPurger;

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

    my @enums = $self->record->enums;
    for my $enum (@enums) {
        next if $enum->layout_id != $self->layout_id;
        $schema->txn_do(sub{
            $enum->update({value => undef});
        });
    }
}

1;