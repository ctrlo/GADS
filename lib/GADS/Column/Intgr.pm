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

package GADS::Column::Intgr;

use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/Bool/;

extends 'GADS::Column';

with 'GADS::Role::Presentation::Column::Intgr';

has '+numeric' => (
    default => 1,
);

has '+addable' => (
    default => 1,
);

has '+return_type' => (
    builder => sub { 'integer' },
);

has '+option_names' => (
    default => sub {
        [{
            name              => 'show_calculator',
            user_configurable => 1,
        }]
    },
);

has show_calculator => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub {
        my $self = shift;
        return 0 unless $self->has_options;
        $self->options->{show_calculator};
    },
    trigger => sub { $_[0]->reset_options },
);

has '+can_multivalue' => (
    default => 1,
);

has '+has_multivalue_plus' => (
    default => 1,
);

sub validate
{   my ($self, $value, %options) = @_;

    foreach my $v (ref $value ? @$value : $value)
    {
        if ($v && $v !~ /^-?[0-9]+$/)
        {
            return 0 unless $options{fatal};
            error __x"'{int}' is not a valid integer for '{col}'",
                int => $v, col => $self->name;
        }
    }
    1;
}

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Intgr')->search({ layout_id => $id })->delete;
}

sub import_value
{   my ($self, $value) = @_;

    $self->schema->resultset('Intgr')->create({
        record_id    => $value->{record_id},
        layout_id    => $self->id,
        child_unique => $value->{child_unique},
        value        => $value->{value},
    });
}

1;

