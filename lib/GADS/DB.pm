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

use String::CamelCase qw(camelize);

sub setup
{   my ($class, $schema) = @_;

    my $layout_rs = $schema->resultset('Layout');
    my @cols = $layout_rs->all;

    foreach my $col (@cols)
    {
        my $coltype = $col->type eq "tree"
                    ? 'enum'
                    : $col->type eq "calc"
                    ? 'calcval'
                    : $col->type eq "rag"
                    ? 'ragval'
                    : $col->type;

        my $colname = "field".$col->id;

        # Temporary hack
        # very inefficient and needs to go away when the rel options show up
        my $rec_class = $schema->class('Record');
        $rec_class->might_have(
            $colname => camelize($coltype),
            sub {
                my $args = shift;

                return {
                    "$args->{foreign_alias}.record_id" => { -ident => "$args->{self_alias}.id" },
                    "$args->{foreign_alias}.layout_id" => $col->id,
                };
            }
        );
        $schema->unregister_source('Record');
        $schema->register_class(Record => $rec_class);
    }

    my $rec_class = $schema->class('Record');
    $rec_class->might_have(
        record_previous => 'Record',
        sub {
            my $args = shift;

            return {
                "$args->{foreign_alias}.current_id"  => { -ident => "$args->{self_alias}.current_id" },
                "$args->{foreign_alias}.id" => { '<' => \"$args->{self_alias}.id" },
            };
        }
    );
    $schema->unregister_source('Record');
    $schema->register_class(Record => $rec_class);

}

1;

