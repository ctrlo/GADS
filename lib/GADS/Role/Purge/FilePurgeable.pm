package GADS::Role::Purge::FilePurgeable;

use strict;
use warnings;

use Encode qw(encode);

use Moo::Role;

with 'GADS::Role::Purgeable';

sub purge {
    my $self = shift;

    my $schema = $self->record_source->schema;

    $schema->txn_do(sub {
        my $value = $self->value;
        $value->update({
            name     => 'purged',
            mimetype => 'text/plain',
            content  => encode('utf-8', 'purged'),
        });
    });
}

1;