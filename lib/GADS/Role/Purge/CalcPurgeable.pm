package GADS::Role::Purge::CalcPurgeable;

use strict;
use warnings;

use Moo::Role;

with 'GADS::Role::Purgeable';

sub purge {
    my $self = shift;
    my @fields = ('value_text', 'value_int', 'value_date', 'value_numeric', 'value_datetime');

    my $schema = $self->result_source->schema;

    $schema->txn_do(sub {
        $self->update({ $_ => undef }) foreach @fields;
    });
}

1;