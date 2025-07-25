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

package GADS::Column::Date;

use DateTime::Format::CLDR;
use DateTime::Format::ISO8601;
use GADS::View;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/Bool/;

extends 'GADS::Column';

with 'GADS::Role::Presentation::Column::Date';

has '+return_type' => (
    builder => sub { 'date' },
);

has '+addable' => (
    default => 1,
);

has '+can_multivalue' => (
    default => 1,
);

has '+has_multivalue_plus' => (
    default => 1,
);

has '+option_names' => (
    default => sub {
        +{
            show_datepicker => 1,
            default_today   => 1,
        }
    },
);

has show_datepicker => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub {
        my $self = shift;
        return 1 unless $self->has_options;
        $self->options->{show_datepicker};
    },
    trigger => sub { $_[0]->reset_options },
);

has default_today => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub {
        my $self = shift;
        return 0 unless $self->has_options;
        $self->options->{default_today};
    },
    trigger => sub { $_[0]->reset_options },
);

sub validate
{   my ($self, $value, %options) = @_;
    return 1 if !$value;
    $self->validate_date($value, %options);
}

sub validate_search
{   my $self = shift;
    $self->validate_search_date(@_) and return 1;
    $self->validate(@_);
}

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Date')->search({ layout_id => $id })->delete;
}

sub import_value
{   my ($self, $value) = @_;

    $self->schema->resultset('Date')->create({
        record_id    => $value->{record_id},
        layout_id    => $self->id,
        child_unique => $value->{child_unique},
        value        => $value->{value} && DateTime::Format::ISO8601->parse_datetime($value->{value}),
    });
}

1;

