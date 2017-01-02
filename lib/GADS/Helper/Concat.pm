=pod
This file is a rip-off of Frew's excellent DBIx::Class::Helpers, but is used to
provide a concatentation function. It would be nice to release this separately,
but for the time being this file only remains copyright (c) 2016 by Arthur Axel
"fREW" Schmidt.

The original licence for this file only is:
This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.
=cut

package GADS::Helper::Concat;

use parent 'DBIx::Class::ResultSet';

use strict;
use warnings;

use DBIx::Introspector;
use Safe::Isa;

sub _flatten_thing {
   my ($self, $thing) = @_;

   die 'you dummy' unless defined $thing;
   my $ref = ref $thing;

   return ('?', $thing) if !$ref;

   if ($ref eq 'HASH' && exists $thing->{'-ident'}) {
      my $thing = $thing->{'-ident'};
      $thing = $self->current_source_alias . $thing if $thing =~ m/^\./;
      return $self->result_source->storage->sql_maker->_quote($thing)
   }

   return ${$thing} if $ref eq 'SCALAR';

   return @{${$thing}};
}

sub _introspector {

   my $d = DBIx::Introspector->new(drivers => '2013-12.01');

   SQLITE: {
      $d->decorate_driver_unconnected(SQLite => concat => sub {
         sub {
             my @fields = map { "COALESCE($_, '')" } @_;
             [ join ' || ', @fields ];
         }
      });
   }

   PG: {
      $d->decorate_driver_unconnected(Pg => concat => sub {
         sub {
             my $fields = join ', ', @_;
             [ "CONCAT( $fields )" ];
         }
      });
   }

   MYSQL: {
      $d->decorate_driver_unconnected(mysql => concat => sub {
         sub {
             my $fields = join ', ', @_;
             [ "CONCAT( $fields )" ];
         }
      });
   }

   return $d;
}

sub helper_concat {
   my ($self, @things) = @_;

   my $storage = $self->result_source->storage;
   $storage->ensure_connected;

   my $d = _introspector();

   @things = map { _flatten_thing $self, $_ } @things;

   return \(
      $d->get($storage->dbh, undef, 'concat')->(
          @things
      )
   );
}

1;
