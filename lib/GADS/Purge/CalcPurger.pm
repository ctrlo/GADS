package GADS::Purge::CalcPurger;

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

    my @calcvals = $self->record->calcvals;
    for my $calcval (@calcvals) {
        next if $calcval->layout_id != $self->layout_id;
        $schema->txn_do(sub {
            my $value = $schema->resultset('Calcval')->find($calcval->id);
            $value->update({ value_text => undef, value_int => undef, value_date => undef, value_numeric => undef });
        });
    }
}

1;