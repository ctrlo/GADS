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

package GADS::Column::Rag;

use Log::Report;

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column::Code';

has green => (
    is  => 'rw',
    isa => Str,
);

has amber => (
    is  => 'rw',
    isa => Str,
);

has red => (
    is  => 'rw',
    isa => Str,
);

after 'build_values' => sub {
    my ($self, $original) = @_;

    my ($rag) = $original->{rags}->[0];
    if ($rag) # RAG defined?
    {
        $self->green($rag->{green}),
        $self->amber($rag->{amber}),
        $self->red($rag->{red}),
    }
};

has unique_key => (
    is      => 'ro',
    default => 'ragval_ux_record_layout',
);

has '+table' => (
    default => 'Ragval',
);

has '+userinput' => (
    default => 0,
);

before 'delete' => sub {
    my $self = shift;
    $self->schema->resultset('Ragval')->search({ layout_id => $self->id })->delete;
};

after 'write' => sub {
    my $self = shift;

    my $rag = {
        red   => $self->red,
        amber => $self->amber,
        green => $self->green,
    };
    my ($ragr) = $self->schema->resultset('Rag')->search({
        layout_id => $self->id
    })->all;
    my $need_update; my $no_alert_send;
    if ($ragr)
    {
        # First see if the calculation has changed
        $need_update =  $ragr->red ne $self->red
                     || $ragr->amber ne $self->amber
                     || $ragr->green ne $self->green;
        $ragr->update($rag);
    }
    else {
        $rag->{layout_id} = $self->id;
        $self->schema->resultset('Rag')->create($rag);
        $need_update   = 1;
        $no_alert_send = 1; # Don't alert on all new values
    }

    if ($need_update)
    {
        my @depends_on;
        foreach my $col ($self->layout->all)
        {
            my $name  = $col->name; my $suffix = $col->suffix;
            my $regex = qr/\Q[$name\E$suffix\Q]/i;
            push @depends_on, $col->id
                if $self->green =~ $regex || $self->amber =~ $regex || $self->red =~ $regex;
        }
        $self->depends_on(\@depends_on);
        $self->update_cached('Ragval', $no_alert_send);
    }
};

1;

