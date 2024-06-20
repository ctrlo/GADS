
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
use Log::Report 'linkspace';
use Safe::Isa;

sub _flatten_thing
{   my ($self, $thing) = @_;

    die 'you dummy' unless defined $thing;
    my $ref = ref $thing;

    return ('?', $thing) if !$ref;

    if ($ref eq 'HASH')
    {
        if (exists $thing->{'-ident'})
        {
            my $thing = $thing->{'-ident'};
            $thing = $self->current_source_alias . $thing if $thing =~ m/^\./;
            return $self->result_source->storage->sql_maker->_quote($thing);
        }
        else
        {
            my ($func, $thing2) = %$thing;
            return "$func(" . $self->_flatten_thing($thing2) . ")";
        }
    }

    return ${$thing} if $ref eq 'SCALAR';

    return @{ ${$thing} };
}

sub _introspector_concat # Do not conflict with _introspector in DBIx::Class::Helper::*
{   my $d = DBIx::Introspector->new(drivers => '2013-12.01');

SQLITE:
    {
        $d->decorate_driver_unconnected(
            SQLite => concat => sub {
                sub {
                    my @fields = map { "COALESCE($_, '')" } @_;
                    [ join ' || ', @fields ];
                },;
            }
        );
        $d->decorate_driver_unconnected(
            SQLite => least => sub {
                sub {
                    # Under some circumstances, sqlite doesn't like only one
                    # value in a MIN()
                    return [ $_[0] ] if @_ == 1;

                    # Aghhhh, Sqlite returns NULL for a MIN() if any one of the
                    # values is a NULL (unlike its aggregate function MIN and
                    # the equivalent Pg function
                    my $fields = join ', ',
                        map "COALESCE($_, '9999-12-31')", @_;
                    ["MIN( $fields )"];
                },;
            }
        );
        $d->decorate_driver_unconnected(
            SQLite => greatest => sub {
                sub {
                    return [ $_[0] ] if @_ == 1;

                    # See comment above
                    my $fields = join ', ',
                        map "COALESCE($_, '0000-01-01')", @_;
                    ["MAX( $fields )"];
                },;
            }
        );
    }

PG:
    {
        $d->decorate_driver_unconnected(
            Pg => concat => sub {
                sub {
                    my $fields = join ', ', @_;
                    ["CONCAT( $fields )"];
                },;
            }
        );
        $d->decorate_driver_unconnected(
            Pg => least => sub {
                sub {
                    my $fields = join ', ', @_;
                    ["LEAST( $fields )"];
                },;
            }
        );
        $d->decorate_driver_unconnected(
            Pg => greatest => sub {
                sub {
                    my $fields = join ', ', @_;
                    ["GREATEST( $fields )"];
                },;
            }
        );
    }

MYSQL:
    {
        $d->decorate_driver_unconnected(
            mysql => concat => sub {
                sub {
                    my $fields = join ', ', @_;
                    ["CONCAT( $fields )"];
                },;
            }
        );
        $d->decorate_driver_unconnected(
            mysql => least => sub {
                sub {
                    my $fields = join ', ', @_;
                    ["LEAST( $fields )"];
                }
            }
        );
        $d->decorate_driver_unconnected(
            mysql => greatest => sub {
                sub {
                    my $fields = join ', ', @_;
                    ["GREATEST( $fields )"];
                }
            }
        );
    }

    return $d;
}

sub _helper
{   my ($self, $type, @things) = @_;

    $type eq 'concat' || $type eq 'least' || $type eq 'greatest'
        or panic "Invalid type $type";

    my $storage = $self->result_source->storage;
    $storage->ensure_connected;

    my $d = _introspector_concat();

    @things = map { _flatten_thing $self, $_ } @things;

    return \($d->get($storage->dbh, undef, $type)->(@things));
}

sub helper_concat
{   my $self = shift;
    $self->_helper('concat', @_);
}

sub helper_least
{   my $self = shift;
    $self->_helper('least', @_);
}

sub helper_greatest
{   my $self = shift;
    $self->_helper('greatest', @_);
}

1;
