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
{   my ($self, $table, $no_alert_send) = @_;

    return unless $self->write_cache;

    # First get all old values, to see if changed
    my @existing = $self->schema->resultset($table)->search({
        layout_id => $self->id,
    },{
        prefetch => 'record',
    })->all;
    my %old = map { $_->record->current_id => $_->value } @existing;

    $self->schema->resultset($table)->search({
        layout_id => $self->id,
    })->delete;

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
    );
    my $depends = $self->depends_on;
    $records->search(
        columns => [@{$depends},$self->id],
    );
    # Force an update on each row
    $_->fields->{$self->id}->value
        foreach (@{$records->results});

    return if $no_alert_send; # E.g. new column, don't want to alert on all

    # Now get new values, and see what's changed
    @existing = $self->schema->resultset($table)->search({
        layout_id => $self->id,
    },{
        prefetch => 'record',
    })->all;
    my %new = map { $_->record->current_id => $_->value } @existing;
    my @changed = grep {
        !(exists $old{$_})
        || !defined $old{$_} && defined $new{$_}
        || defined $old{$_} && !defined $new{$_}
        || (defined $old{$_} && defined $new{$_} && $old{$_} ne $new{$_})
    } keys %new;
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

