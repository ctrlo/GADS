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

package GADS::Column::Code;

use GADS::AlertSend;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column';

has write_cache => (
    is      => 'rw',
    default => 1,
);

has base_url => (
    is => 'rw',
);

sub update_cached
{   my ($self, $table, $no_alert_send, $value_field_old) = @_;

    return unless $self->write_cache;

    # $@ may be the result of a previous Log::Report::Dispatcher::Try block (as
    # an object) and may evaluate to an empty string. If so, txn_scope_guard
    # warns as such, so undefine to prevent the warning
    undef $@;
    my $guard = $self->schema->txn_scope_guard;

    # Need to refresh layout for updated calculation. Also
    # need it for the dependent fields
    my $layout = GADS::Layout->new(
        instance_id => $self->layout->instance_id,
        user        => $self->user,
        config      => $self->layout->config,
        schema      => $self->schema,
    );
    my $records = GADS::Records->new(
        user         => $self->user,
        layout       => $layout,
        schema       => $self->schema,
        force_update => [ $self->id ],
        columns      => [@{$self->depends_on},$self->id],
    );

    my @changed;
    while (my $record = $records->single)
    {
        $record->fields->{$self->id}->value;
        push @changed, $record->current_id if $record->fields->{$self->id}->changed;
    }

    $guard->commit;

    return if $no_alert_send; # E.g. new column, don't want to alert on all

    # Send any alerts
    my $alert_send = GADS::AlertSend->new(
        layout      => $self->layout,
        schema      => $self->schema,
        user        => $self->user,
        base_url    => $self->base_url,
        current_ids => \@changed,
        columns     => [$self->id],
    );
    $alert_send->process;
};

1;

