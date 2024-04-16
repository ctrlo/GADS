package GADS::Purge::RecordsPurger;

use strict;
use warnings;

use GADS::Purge::RecordPurger;

use Moo;

extends 'GADS::Purge::Purger';

has layout_type => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        die "layout_type must be a string" unless defined $_[0] && !ref $_[0];
        die "Layout must be one of " unless $_[0] =~ /^(?:calc|rag|person|file|tree|enum|daterange|date|ingr|string)$/i;
    },
);

has records => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        die "records must be an array reference" unless ref $_[0] eq 'ARRAY';
    },
);

has record_id => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        die "record_id must be a positive integer" unless $_[0] =~ /^\d+$/;
    },
);

sub purge {
    my $self = shift;

    die "No records to purge" unless @{$self->records};

    my $count = 0;
    foreach my $record (@{$self->records}) {
        next unless $record->id == $self->record_id;
        $self->purge_record($record);
        $count++;
    }

    return $count;
}

sub purge_record {
    my ($self, $record) = @_;

    my $record_purger = GADS::Purge::RecordPurger->new(
        layout_id   => $self->layout_id,
        schema      => $self->schema,
        layout_type => $self->layout_type,
        record      => $record,
    );
    $record_purger->purge();
}

1;