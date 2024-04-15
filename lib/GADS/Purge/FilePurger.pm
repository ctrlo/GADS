package GADS::Purge::FilePurger;

use strict;
use warnings;

use feature 'say';

use Encode qw(encode);

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

    my @files = $self->record->files;
    for my $file (@files) {
        next if $file->layout_id != $self->layout_id;
        $schema->txn_do(sub {
            my $value = $file->value;
            $value->update({
                name     => 'purged',
                mimetype => 'text/plain',
                content  => encode('utf-8', 'purged'),
            });
        });
    }
}

1;