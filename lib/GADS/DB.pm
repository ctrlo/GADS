
=pod
GADS - Globally Accessible Data Store
Copyright (C) 2014 Ctrl O Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

package GADS::DB;

use strict;
use warnings;

use String::CamelCase qw(camelize);

sub setup
{   my ($class, $schema) = @_;

    my $layout_rs = $schema->resultset('Layout');
    my @cols      = $layout_rs->all;

    foreach my $col (@cols)
    {
        $class->add_column($schema, $col);
    }

    my $rec_class = $schema->class('Record');
    $rec_class->might_have(
        record_previous => 'Record',
        sub {
            my $args = shift;

            return {
                "$args->{foreign_alias}.current_id" =>
                    { -ident => "$args->{self_alias}.current_id" },
                "$args->{foreign_alias}.id" =>
                    { '<' => \"$args->{self_alias}.id" },
            };
        },
    );

    GADS::Schema->unregister_source('Record');
    GADS::Schema->register_class(Record => $rec_class);

    $schema->unregister_source('Record');
    $schema->register_class(Record => $rec_class);

}

sub add_column
{   my $self = shift;
    $self->_add_column(@_);
    $self->_add_column(@_, 1);
}

sub _add_column
{   my ($class, $schema, $col, $alt) = @_;
    return if $col->internal; # Result sources are only added for "real" columns
    my $coltype =
          $col->type eq "tree" ? 'enum'
        : $col->type eq "calc" ? 'calcval'
        : $col->type eq "rag"  ? 'ragval'
        :                        $col->type;

    my $colname = "field" . $col->id;

    # We add each column twice, with a standard join and with an alternative
    # join. The alternative join allows correlated sub-queries to be used, with
    # the inner sub-query referencing a value from the main query
    $colname .= "_alternative" if $alt;

    # Temporary hack
    # very inefficient and needs to go away when the rel options show up
    my $rec_class = $schema->class('Record');
    if ($col->type eq 'autocur')
    {
        # Capture now before any weakrefs go out of scope
        my $related_field_id = $col->related_field->id;

        my $subquery = $schema->resultset('Current')->search(
            {
                'record_later.id' => undef,
            },
            {
                join => {
                    'record_single' => 'record_later'
                },
            },
        )->get_column('record_single.id')->as_query;
        $rec_class->has_many(
            $colname => 'Curval',
            sub {
                my $args = shift;

                return {
                    "$args->{foreign_alias}.value" =>
                        { -ident => "$args->{self_alias}.current_id" },
                    "$args->{foreign_alias}.layout_id" => $related_field_id,
                    "$args->{foreign_alias}.record_id" =>
                        { -in => $subquery },
                };
            },
        );
    }
    else
    {
        $rec_class->has_many(
            $colname => $coltype eq 'filval'
            ? 'Curval'
            : camelize($coltype),
            sub {
                my $args = shift;

                return {
                    "$args->{foreign_alias}.record_id" =>
                        { -ident => "$args->{self_alias}.id" },
                    "$args->{foreign_alias}.layout_id" => $col->id,
                };
            },
        );
    }

    GADS::Schema->unregister_source('Record');
    GADS::Schema->register_class(Record => $rec_class);

    $schema->unregister_source('Record');
    $schema->register_class(Record => $rec_class);
}

sub update
{   my ($class, $schema) = @_;

    # Find out what latest field ID is
    my $max =
        $schema->resultset('Layout')->search({ internal => 0 })
        ->get_column('id')->max
        or return;    # No fields

    # Does this exist as an accessor?
    my $rec_rsource = $schema->resultset('Record')->result_source;
    unless ($rec_rsource->has_relationship("field$max"))
    {
        # No. Need to go back until we find the one that exists
        my $id = $max;
        $id-- while !$rec_rsource->has_relationship("field$id");
        $id++;    # Start at one the doesn't exist
        for ($id .. $max)
        {
            # Add them/it
            my $col = $schema->resultset('Layout')->find($_);
            $class->add_column($schema, $col)
                if $col;    # May have since been deleted
            $class->add_column($schema, $col, 1)
                if $col;    # May have since been deleted
        }
    }
}

1;

