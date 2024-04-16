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
        die "Layout of invalid type: " . $_[0] unless $_[0] =~ /^(?:[cC]alc|[Rr][Aa][Gg]|[pP]erson|[fF]ile|[tT]ree|[eE]num|[dD]aterange|[dD]ate|[iI]ngr|[sS]tring|[iI]ntgr)$/i;
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

has schema => (
    is      => 'ro',
    required => 1,
    isa      => sub {
        die "schema must be a GADS::Schema object" unless ref $_[0] eq 'GADS::Schema';
    },
);

has layout_id =>(
    is       => 'ro',
    required => 1,
    isa      => sub {
        die "layout_id must be a positive integer" unless $_[0] =~ /^\d+$/;
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

    my $layout_id = $self->layout_id or die "No layout_id";
    my $schema    = $self->schema    or die "No schema";
    my $layout_type = $self->layout_type or die "No layout_type";

    my $record_purger = GADS::Purge::RecordPurger->new(
        layout_id   => $layout_id,
        schema      => $schema,
        layout_type => $layout_type,
        record      => $record,
    );
    $record_purger->purge();
}

1;