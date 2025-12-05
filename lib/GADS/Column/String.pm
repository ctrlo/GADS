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

use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/Bool Str Maybe/;

extends 'GADS::Column';

with 'GADS::Role::Presentation::Column::String';

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

has '+can_multivalue' => (
    default => 1,
);

has '+has_multivalue_plus' => (
    default => 1,
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

    return ();
};

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('String')->search({ layout_id => $id })->delete
}

sub resultset_for_values
{   my $self = shift;
    return $self->schema->resultset('String')->search({
        layout_id => $self->id,
    },{
        group_by => 'me.value',
    });
}

before import_hash => sub {
    my ($self, $values, %options) = @_;
    my $report = $options{report_only} && $self->id;
    notice __x"Update: textbox from {old} to {new}", old => $self->textbox, new => $values->{textbox}
        if $report && $self->textbox != $values->{textbox};
    $self->textbox($values->{textbox});
    notice __x"Update: force_regex from {old} to {new}", old => $self->force_regex, new => $values->{force_regex}
        if $report && ($self->force_regex || '') ne ($values->{force_regex} || '');
    $self->force_regex($values->{force_regex});
};

around export_hash => sub {
    my $orig = shift;
    my ($self, $values) = @_;
    my $hash = $orig->(@_);
    $hash->{textbox}     = $self->textbox;
    $hash->{force_regex} = $self->force_regex;
    return $hash;
};

sub import_value
{   my ($self, $value) = @_;

    $self->schema->resultset('String')->create({
        record_id    => $value->{record_id},
        layout_id    => $self->id,
        child_unique => $value->{child_unique},
        value        => $value->{value},
        value_index  => $value->{value_index},
    });
}

1;

