package GADS::Schema::ResultSet::Current;

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

__PACKAGE__->load_components(qw/Helper::ResultSet::DateMethods1 +GADS::Helper::Concat/);

1;
