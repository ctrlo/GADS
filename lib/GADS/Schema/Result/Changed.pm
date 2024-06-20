package GADS::Schema::Result::Changed;

# A result class that simply uses directly the query in GADS::Helper::Changed.
# This returns a set of current IDs of records that have changed, based on the
# parameters in the global $GADS::Helper::Changed::CHANGED_PARAMS.
# XXX Question: can the global be removed and the parameters passed via this
# class instead?

use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('GADS::Helper::Changed');

__PACKAGE__->table('xxx');    # DBIx::Class borks without this set

__PACKAGE__->result_source_instance->is_virtual(1);

1;
