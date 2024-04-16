package GADS::Purge::RecordPurger;

use strict;
use warnings;

use GADS::Purge::DateRangePurger;
use GADS::Purge::DatePurger;
use GADS::Purge::EnumPurger;
use GADS::Purge::IntPurger;
use GADS::Purge::PeoplePurger;
use GADS::Purge::StringPurger;
use GADS::Purge::FilePurger;
use GADS::Purge::CalcPurger;

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

has record => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        die "record must be a record reference" unless ref $_[0] eq 'GADS::Schema::Result::Record';
    },
);

has record_id => (
    is       => 'ro',
    required => 0,
);

has schema => (
    is       => 'ro',
    required => 1,
);

has layout_id => (
    is       => 'ro',
    required => 1,
);

sub purge {
    my $self = shift;

    die "Record is required" unless $self->record;

    $self->_purge_strings() if $self->layout_type eq 'string';
    $self->_purge_date_ranges() if $self->layout_type eq 'daterange';
    $self->_purge_dates() if $self->layout_type eq 'date';
    $self->_purge_enums() if $self->layout_type eq 'enum' || $self->layout_type eq 'tree';
    $self->_purge_ints() if $self->layout_type eq 'intgr';
    $self->_purge_people() if $self->layout_type eq 'person';
    $self->_purge_files() if $self->layout_type eq 'file';
    $self->_purge_calcs() if $self->layout_type eq 'rag' || $self->layout_type eq 'calc';
}

sub _purge_strings {
    my $self = shift;

    my $layout_id = $self->layout_id or die "Invalid Layout ID";
    my $schema = $self->schema or die "Invalid Schema";
    my $record = $self->record or die "Invalid Record";

    my $string_purger = GADS::Purge::StringPurger->new(
        layout_id => $layout_id,
        schema    => $schema,
        record    => $record,
    );
    $string_purger->purge();
}

sub _purge_date_ranges {
    my $self = shift;

    my $date_range_purger = GADS::Purge::DateRangePurger->new(
        layout_id => $self->layout_id,
        schema    => $self->schema,
        record    => $self->record,
    );
    $date_range_purger->purge();
}

sub _purge_dates {
    my $self = shift;

    my $date_purger = GADS::Purge::DatePurger->new(
        layout_id => $self->layout_id,
        schema    => $self->schema,
        record    => $self->record,
    );
    $date_purger->purge();
}

sub _purge_enums {
    my $self = shift;

    my $enum_purger = GADS::Purge::EnumPurger->new(
        layout_id => $self->layout_id,
        schema    => $self->schema,
        record    => $self->record,
    );
    $enum_purger->purge();
}

sub _purge_ints {
    my $self = shift;

    my $int_purger = GADS::Purge::IntPurger->new(
        layout_id => $self->layout_id,
        schema    => $self->schema,
        record    => $self->record,
    );
    $int_purger->purge();
}

sub _purge_people {
    my $self = shift;

    my $people_purger = GADS::Purge::PeoplePurger->new(
        layout_id => $self->layout_id,
        schema    => $self->schema,
        record    => $self->record,
    );
    $people_purger->purge();
}

sub _purge_files {
    my $self = shift;

    my $files_purger = GADS::Purge::FilePurger->new(
        layout_id => $self->layout_id,
        schema    => $self->schema,
        record    => $self->record,
    );
    $files_purger->purge();
}

sub _purge_calcs {
    my $self = shift;

    my $calc_purger = GADS::Purge::CalcPurger->new(
        layout_id => $self->layout_id,
        schema    => $self->schema,
        record    => $self->record,
    );
    $calc_purger->purge();
}

1;