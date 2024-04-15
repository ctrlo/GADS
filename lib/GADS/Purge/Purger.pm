package GADS::Purge::Purger;

use strict;
use warnings;

use Moo;

has record_id => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        die "record_id must be a positive integer" unless $_[0] =~ /^\d+$/;
    },
);

has layout_id => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        die "layout_id must be a positive integer" unless $_[0] =~ /^\d+$/;
    },
);

has schema => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        die "schema must be a GADS::Schema object: " . ref($_[0]) unless ref $_[0] eq 'GADS::Schema';
    },
);

sub purge {
    my $self = shift;
    my $schema = $self->schema or die "No schema";
    my $layout_id = $self->layout_id or die "No layout_id";
    my $record_id = $self->record_id or die "No record_id";

    my $layout = $schema->resultset('Layout')->find({ id => $layout_id }) or die "No layout found";
    my $layout_type = $layout->type;
    my $instance = $layout->instance;
    my @currents = $instance->currents;

    foreach my $current (@currents) {
        my @records = $current->records();
        my $purger = GADS::Purge::RecordsPurger->new(
            schema    => $schema,
            record_id => $record_id,
            layout_id => $layout_id,
            layout_type => $layout_type,
            records   => \@records);
        $purger->purge();
    }
}

1;