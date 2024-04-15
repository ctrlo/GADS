package GADS::Purge::DatePurger;

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

    my $schema = $self->schema or die "Invalid schema or no schema provided";

    my @dates = $self->record->dates;
    for my $date (@dates) {
        next if $date->layout_id != $self->layout_id;
        $schema->txn_do(sub {
            $date->update({value=>undef});
        });
    }
}

1;