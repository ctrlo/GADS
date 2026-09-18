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

use Log::Report 'linkspace';

use Moo;

extends 'GADS::Column::Code';

with 'GADS::Role::Presentation::Column::Rag';

has '+type' => (
    default => 'rag',
);

sub _build__rset_code
{   my $self = shift;
    $self->_rset or return;
    my ($code) = $self->_rset->rags;
    if (!$code)
    {
        $code = $self->schema->resultset('Rag')->new({});
    }
    return $code;
}

has unique_key => (
    is      => 'ro',
    default => 'ragval_ux_record_layout',
);

has '+table' => (
    default => 'Ragval',
);

has '+fixedvals' => (
    default => 1,
);

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Rag')->search({ layout_id => $id })->delete;
    $schema->resultset('Ragval')->search({ layout_id => $id })->delete;
}

# Returns whether an update is needed
sub write_code
{   my ($self, $layout_id) = @_;
    my $rset = $self->_rset_code;
    my $need_update = !$rset->in_storage
        || $self->_rset_code->code ne $self->code;
    $rset->layout_id($layout_id);
    $rset->code($self->code);
    $rset->insert_or_update;
    return $need_update;
}

before import_hash => sub {
    my ($self, $values, %options) = @_;
    my $report = $options{report_only} && $self->id;
    notice __x"Update: RAG code has changed for {name}",
        name => $self->name
            if $report && $self->code ne $values->{code};
    $self->code($values->{code});
};

around export_hash => sub {
    my $orig = shift;
    my ($self, $values) = @_;
    my $hash = $orig->(@_);
    $hash->{code} = $self->code;
    return $hash;
};

1;

