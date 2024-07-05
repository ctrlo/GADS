package GADS::Schema::ResultSet::Current;

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

use Log::Report 'linkspace';

__PACKAGE__->load_components(qw/
    Helper::ResultSet::DateMethods1
    +GADS::Helper::Concat
    Helper::ResultSet::CorrelateRelationship
    Helper::ResultSet::Random
    /
);

sub historic_purge {
    my ($self, $user, $current_ids, $layouts) = @_;

    error __"Please select some values to delete" if !$current_ids || !@$current_ids;
    error __"Please select some layouts to delete" if !$layouts || !@$layouts;

    my @result = $self->search({id=>{-in=>$current_ids}})->all;

    $_->historic_purge($user, $layouts)
        foreach @result;
}

sub active_rs
{   shift->search({
        'me.deleted'      => undef,
        'me.draftuser_id' => undef,
    });
}

sub import_hash
{   my ($self, $record, %params) = @_;

    my $schema = $self->result_source->schema;

    my $current = $self->create({
        instance_id => $params{instance}->id,
        serial      => $record->{serial},
        deleted     => $record->{deleted},
        deletedby   => $record->{deletedby} && $params{user_mapping}->{$record->{deletedby}},
    });

    foreach my $r (@{$record->{records}})
    {
        error __"Import of record_id value not yet support"
            if $r->{record_id};
        my $rec = $schema->resultset('Record')->import_hash($r, current => $current, %params);
    }

    return $current;
}

1;
