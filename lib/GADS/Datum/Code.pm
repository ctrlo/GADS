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

use Data::Dumper;
use GADS::Safe;
use String::CamelCase qw(camelize); 
use Log::Report;
use Moo;
use namespace::clean;

extends 'GADS::Datum';

has set_value => (
    is      => 'rw',
    trigger => sub {
        my $self = shift;
        $self->_set_has_value(1);
    },
);

has value => (
    is       => 'rw',
    lazy     => 1,
    clearer  => 1,
    builder  => sub {
        my $self = shift;
        $self->_transform_value($self->init_value);
    },
);

has has_value => (
    is => 'rwp',
);

has layout => (
    is       => 'rw',
    required => 1,
);

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

has vars => (
    is => 'lazy',
);

sub _build_vars
{   my $self = shift;
    $self->record->values_by_shortname($self->column->params);
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

sub _transform_value
{   my ($self, $original) = @_;

    my $column = $self->column;
    my $layout = $self->layout;
    my $code   = $column->code;

    my $value;

    if (ref $original && !$self->force_update)
    {
        my $v  = $original->[0]->{$column->value_field};
        $value = $column->return_type eq 'date'
               ? $self->_parse_date($v)
               : $v;
    }
    elsif (!$code)
    {
        # Nothing, $value stays undef
    }
    else {
        # Used during tests to check that $original is being set correctly
        panic "Entering calculation code"
            if $ENV{GADS_PANIC_ON_ENTERING_CODE};

        try { $value = $column->eval($self->column->code, $self->vars) };
        if ($@ || $value->{error})
        {
            my $error = $@ ? $@->wasFatal->message->toString : $value->{error};
            warning __x"Failed to eval calc: {error} (code: {code}, params: {params})",
                error => $error, code => $code, params => Dumper($self->vars);
            $value->{error} = 1;
        }

        $value = $self->convert_value($value); # Convert value as required by calc/rag

        $self->write_value($value);
    }

    $value;
}

1;
