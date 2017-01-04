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

package GADS::Datum::Code;

use GADS::Safe;
use String::CamelCase qw(camelize); 
use Log::Report;
use Moo;
use namespace::clean;

extends 'GADS::Datum';

has force_update => (
    is      => 'rw',
    trigger => sub {
        my $self = shift;
        $self->clear_value;
    },
);

has schema => (
    is       => 'rw',
    required => 1,
);

has dependent_values => (
    is       => 'rw',
    required => 1,
);

sub _sub_param_values
{   my ($self, @params) = @_;
    [
        map {
            my $id = $self->layout->column_by_name_short($_)->id;
            $self->dependent_values->{$id}->for_code;
        } @params
    ];
}

sub write_cache
{   my ($self, $table, $value) = @_;

    # $@ may be the result of a previous Log::Report::Dispatcher::Try block (as
    # an object) and may evaluate to an empty string. If so, txn_scope_guard
    # warns as such, so undefine to prevent the warning
    undef $@;
    # We are generally already in a transaction at this point, but
    # start another one just in case
    my $guard = $self->schema->txn_scope_guard;

    my $tablec = camelize $table;
    # The cache tables have unqiue constraints to prevent
    # duplicate cache values for the same records. Using an eval
    # catches any attempts to write duplicate values.
    my $vfield = $self->column->value_field;
    my $row = $self->schema->resultset($tablec)->find({
        record_id => $self->record_id,
        layout_id => $self->column->{id},
    },{
        key => $self->column->unique_key,
    });

    if ($row)
    {
        if (!$self->equal($row->$vfield, $value))
        {
            my %blank = %{$self->column->blank_row};
            $row->update({ %blank, $vfield => $value });
            $self->changed(1);
        }
    }
    else {
        $self->schema->resultset($tablec)->create({
            record_id => $self->record_id,
            layout_id => $self->column->{id},
            $vfield   => $value,
        });
    }
    $guard->commit;
    $value;
}

sub safe_eval
{   my($self, $code) = @_;
    Inline->bind(Lua => $code);
    evaluate(@{$self->params});
}

1;

