package GADS::Schema::ResultSet::Report;

use strict;
use warnings;

use Log::Report 'linkspace';

use parent 'DBIx::Class::ResultSet';

# All reports not deleted
sub extant
{   my $self = shift;
    $self->search({
        'me.deleted' => undef,
    });
}

=head1 Package functions
=head2 Load
Function to load a report for a given id - it requires the report id, and record id to be passed in and will return a report object
=cut

sub load
{   my ($self, $id, $record_id) = @_;

    my $result = load_for_edit($self, $id)
        or return undef;

    $result->record_id($record_id);

    return $result;
}

=head2 Load for Edit
Function to load a report for a given id - it requires the report id to be passed in and will return a report object for editing
=cut

sub load_for_edit
{   my ($self, $id) = @_;

    $self->extant->find($id, {
        prefetch => 'report_layouts',
    }) or error __x"No report found for id {id}", id => $id;
}

=head2
Function to load all reports for a given instance - it requires the instance id to be passed in and will return an array of report objects
=cut

sub load_all_reports
{   my ($self, $instance_id) = @_;

    my $items = $self->extant->search({
        instance_id => $instance_id,
    }, {
        prefetch => 'report_layouts',
    });

    return [ $items->all ];
}

=head2 Create
Function to create a new report - it requires a hash of the report data to be passed in and will return a report object
=cut

sub create_report
{   my ($self, $args) = @_;

    my $schema = $self->result_source->schema;

    my $guard = $schema->txn_scope_guard;

    my @user_groups = $args->{user}->groups;

    my $groups  = [ map { { group_id  => $_->id } } @{ $args->{user_groups} } ];
    my $layouts = [ map { { layout_id => $_ } } @{ $args->{layouts} } ];

    my $report = $self->create({
        user             => $args->{user},
        name             => $args->{name},
        title            => $args->{title},
        description      => $args->{description},
        instance_id      => $args->{instance_id},
        createdby        => $args->{user},
        created          => DateTime->now,
        report_layouts   => $layouts,
        security_marking => $args->{security_marking},
        report_groups    => $groups,
    });

    $guard->commit;

    return $report;
}

sub find_with_permission {
    my ($self, $id, $user) = @_;

    $self->extant->search({
        'me.id'                  => $id,
        'report_groups.group_id' => {
            -in => [ map { $_->id } $user->groups ]
        }
    },{
        prefetch => ['report_groups', 'report_layouts']
    })->next;
}

1;
