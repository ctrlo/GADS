package GADS::Purge::StringPurger;

use strict;
use warnings;

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

    my @strings = $self->record->strings;
    for my $string (@strings) {
        next if $string->layout_id != $self->layout_id;
        $schema->txn_do(sub {
            my $value = $schema->resultset('String')->search({ id => $string->id });
            $value->update({ value => undef });
        });
    }
}

1;