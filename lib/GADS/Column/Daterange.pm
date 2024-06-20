
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

package GADS::Column::Daterange;

use DateTime;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column';

with 'GADS::Role::Presentation::Column::Daterange';
with 'GADS::DateTime';

has '+return_type' => (builder => sub { 'daterange' },);

has '+addable' => (default => 1,);

has '+can_multivalue' => (default => 1,);

has '+has_multivalue_plus' => (default => 1,);

has '+option_names' => (default => sub { [qw/show_datepicker/] },);

sub _build_retrieve_fields
{   my $self = shift;
    [qw/from to/];
}

# Still counts as string storage for search (value field is string)
has '+string_storage' => (default => sub { shift->return_type eq 'string' },);

sub _build_sort_field { 'from' }

# The from and to fields from the database table
sub from_field { 'from' }
sub to_field   { 'to' }

has show_datepicker => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub {
        my $self = shift;
        return 0 unless $self->has_options;
        $self->options->{show_datepicker};
    },
    trigger => sub { $_[0]->reset_options },
);

sub validate
{   my $self = shift;
    $self->validate_daterange(@_);
}

sub validate_search
{   my $self = shift;
    $self->validate_daterange_search(@_);
}

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Daterange')->search({ layout_id => $id })->delete;
}

sub import_value
{   my ($self, $value) = @_;

    $self->schema->resultset('Daterange')->create({
        record_id    => $value->{record_id},
        layout_id    => $self->id,
        child_unique => $value->{child_unique},
        from         => $value->{from}
            && DateTime::Format::ISO8601->parse_datetime($value->{from}),
        to => $value->{to}
            && DateTime::Format::ISO8601->parse_datetime($value->{to}),
        value => $value->{value},
    });
}

1;

