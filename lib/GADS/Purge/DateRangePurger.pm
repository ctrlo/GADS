package GADS::Purge::DateRangePurger;

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

    my $schema = $self->schema or die "Invalid schema or schema not provided";

    my @dateranges = $self->record->dateranges;
    for my $daterange (@dateranges) {
        next if $daterange->layout_id != $self->layout_id;
        $schema->txn_do(sub {
            $daterange->update({
                from => undef,
                to   => undef,
            });
        });
    }
}

1;