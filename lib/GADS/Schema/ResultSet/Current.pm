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

1;
