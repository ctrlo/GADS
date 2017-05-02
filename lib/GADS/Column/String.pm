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

package GADS::Column::String;

use Log::Report;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column';

has textbox => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    default => 0,
    coerce  => sub { $_[0] ? 1 : 0 },
);

has force_regex => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
);

after 'build_values' => sub {
    my ($self, $original) = @_;
    $self->string_storage(1);

    if ($original->{textbox})
    {
        $self->textbox(1);
    }
    if (my $force_regex = $original->{force_regex})
    {
        $self->force_regex($force_regex);
    }
};

sub write_special
{   my ($self, %options) = @_;

    my $rset = $options{rset};

    $rset->update({
        textbox     => $self->textbox,
        force_regex => $self->force_regex,
    });
};

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('String')->search({ layout_id => $id })->delete
}

sub import_hash
{   my ($self, $values) = @_;
    $self->import_common($values);
    $self->textbox($values->{textbox});
    $self->force_regex($values->{force_regex});
}

sub export
{   my $self = shift;
    my $hash = $self->export_common;
    $hash->{textbox}     = $self->textbox;
    $hash->{force_regex} = $self->force_regex;
    $hash;
}

1;

