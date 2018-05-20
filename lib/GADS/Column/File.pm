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

package GADS::Column::File;

use Log::Report 'linkspace';

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column';

has filesize => (
    is      => 'rw',
    isa     => Maybe[Int],
);

has '+fixedvals' => (
    default => 1,
);

sub _build_sprefix { 'value' };

after build_values => sub {
    my ($self, $original) = @_;

    $self->value_field('name');
    my ($file_option) = $original->{file_options}->[0];
    if ($file_option)
    {
        $self->filesize($file_option->{filesize});
    }
};

sub write_special
{   my ($self, %options) = @_;

    my $id   = $options{id};

    my $foption = {
        filesize => $self->filesize,
    };
    my ($file_option) = $self->schema->resultset('FileOption')->search({
        layout_id => $id,
    })->all;
    if ($file_option)
    {
        $file_option->update($foption);
    }
    else {
        $foption->{layout_id} = $id;
        $self->schema->resultset('FileOption')->create($foption);
    }
};

sub _build_join
{   my $self = shift;
    +{$self->field => 'value'};
}

sub cleanup
{   my ($class, $schema, $id)  = @_;
    $schema->resultset('File')->search({ layout_id => $id })->delete;
    $schema->resultset('FileOption')->search({ layout_id => $id })->delete;
};

before import_hash => sub {
    my ($self, $values) = @_;
    $self->filesize($values->{filesize});
};

around export_hash => sub {
    my $orig = shift;
    my ($self, $values) = @_;
    my $hash = $orig->(@_);
    $hash->{filesize} = $self->filesize;
    return $hash;
};

1;

