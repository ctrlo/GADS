package GADS::Schema::ResultSet::Current;

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

__PACKAGE__->load_components(qw/
    Helper::ResultSet::DateMethods1
    +GADS::Helper::Concat
    Helper::ResultSet::CorrelateRelationship/
);

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
        deletedby   => $record->{deletedby},
    });

    foreach my $r (@{$record->{records}})
    {
        my $rec = $schema->resultset('Record')->import_hash($r, current => $current, %params);
    }

    return $current;
}

1;
