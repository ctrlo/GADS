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

package GADS::Column::Calc;

use Log::Report;

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column::Code';

has calc => (
    is  => 'rw',
    isa => Str,
);

has decimal_places => (
    is  => 'rw',
    isa => Maybe[Int],
);

after 'build_values' => sub {
    my ($self, $original) = @_;

    my ($calc) = $original->{calcs}->[0];
    if ($calc) # Calculations defined?
    {
        $self->calc($calc->{calc});
        $self->return_type($calc->{return_format});
        $self->decimal_places($calc->{decimal_places});
        $self->numeric($self->return_type eq 'integer' || $self->return_type eq 'date' || $self->return_type eq 'numeric');
        $self->value_field(
            $self->return_type eq 'date'
            ? 'value_date'
            : $self->return_type eq 'integer'
            ? 'value_int'
            : $self->return_type eq 'numeric'
            ? 'value_numeric'
            : 'value_text'
        );
        $self->string_storage(1) if $self->return_type eq 'string';
    }
    $self->table("Calcval");
    $self->userinput(0);
};

before 'delete' => sub {
    my $self = shift;
    $self->schema->resultset('Calcval')->search({ layout_id => $self->id })->delete;
};

after 'write' => sub {
    my $self = shift;

    # Existing calculation defined?
    my ($calcr) = $self->schema->resultset('Calc')->search({
        layout_id => $self->id,
    })->all;

    my $need_update; my $no_alert_send;
    if ($calcr)
    {
        # First see if the calculation has changed
        $need_update = $calcr->calc ne $self->calc
            || $calcr->return_format ne $self->return_type;
        $calcr->update({
            calc          => $self->calc,
            return_format => $self->return_type,
        });
    }
    else {
        $calcr = $self->schema->resultset('Calc')->create({
            calc          => $self->calc,
            layout_id     => $self->id,
            return_format => $self->return_type,
        });
        $need_update   = 1;
        $no_alert_send = 1; # Don't send alerts on all new values
    }

    if ($need_update)
    {
        my @depends_on;
        foreach my $col ($self->layout->all)
        {
            my $name  = $col->name; my $suffix = $col->suffix;
            push @depends_on, $col->id
                if $self->calc =~ /\Q[$name\E$suffix\Q]/i;
        }
        $self->depends_on(\@depends_on);
        $self->update_cached('Calcval', $no_alert_send);
    }
};

sub resultset_for_values
{   my $self = shift;
    return $self->schema->resultset('Calcval')->search({
        layout_id => $self->id,
    },{
        group_by  => 'me.'.$self->value_field,
    }) if $self->return_type eq 'string';
}

1;

