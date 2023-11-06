package GADS::Schema::ResultSet::Report;

use strict;
use warnings;

use Log::Report 'linkspace';

use parent 'DBIx::Class::ResultSet';

=head1 Package functions

=head2 Load

Function to load a report for a given id - it requires the report id, and record id to be passed in and will return a report object

=cut

sub load {
    my ( $self, $id, $record_id ) = @_;

    my $schema = $self->result_source->schema;

    error "Invalid report id provided"
      unless $id && $id =~ /^\d+$/;

    my $result = $self->find( { id => $id }, { prefetch => 'report_layouts' } )
      or error "No report found for id $id";
    $result->record_id($record_id);

    return $result if !$result->deleted || $result->deleted == 0;
    return undef;
}

=head2 Load for Edit

Function to load a report for a given id - it requires the report id to be passed in and will return a report object for editing

=cut

sub load_for_edit {
    my ( $self, $id ) = @_;

    my $schema = $self->result_source->schema;

    my $result = $self->find( { id => $id }, { prefetch => 'report_layouts' } )
      or error "No report found for id $id";

    return $result if !$result->deleted || $result->deleted == 0;
    return undef;
}

=head2

Function to load all reports for a given instance - it requires the instance id to be passed in and will return an array of report objects

=cut

sub load_all_reports {

    my ( $self, $instance_id ) = @_;

    my $schema = $self->result_source->schema;

    my $items = $self->search(
        {
            instance_id => $instance_id,
            deleted     => 0
        },
        {
            prefetch => 'report_layouts',
        }
    );

    my $result = [];

    while ( my $next = $items->next ) {
        push( @{$result}, $next );
    }

    return $result;
}

=head2 Create

Function to create a new report - it requires a hash of the report data to be passed in and will return a report object

=cut

sub create_report {
    my ( $self, $args ) = @_;

    my $schema = $self->result_source->schema;

    my $guard = $schema->txn_scope_guard;

    my $layouts = [ map { { layout_id => $_ } } @{ $args->{layouts} } ];

    my $report = $self->create(
        {
            user           => $args->{user},
            name           => $args->{name},
            description    => $args->{description},
            instance_id    => $args->{instance_id},
            createdby      => $args->{user},
            created        => DateTime->now,
            deleted        => 0,
            report_layouts => $layouts,
        }
    );

    $guard->commit;

    return $report;
}

1;
