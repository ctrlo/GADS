=pod
GADS
Copyright (C) 2015 Ctrl O Ltd

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

package GADS::Instance;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use overload 'bool' => sub { 1 }, '""'  => 'as_string', '0+' => 'as_integer', fallback => 1;

has schema => (
    is       => 'ro',
    required => 1,
);

has id => (
    is  => 'rwp',
    isa => Maybe[Int],
);

has _rset => (
    is      => 'rwp',
    lazy    => 1,
    builder => 1,
);

has site => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->site; },
);

has name => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->name; },
);

has email_delete_text => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->email_delete_text; },
);

has email_delete_subject => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->email_delete_subject; },
);

has email_reject_text => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->email_reject_text; },
);

has email_reject_subject => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->email_reject_subject; },
);

has homepage_text => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->homepage_text; },
);

has homepage_text2 => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->homepage_text2; },
);

has sort_layout_id => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    coerce  => sub { $_[0]||undef },
    builder => sub { $_[0]->_rset && $_[0]->_rset->sort_layout_id; },
);

has sort_type => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->sort_type; },
);

has register_text => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->register_text; },
);

has register_title_help => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->register_title_help; },
);

has register_email_help => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->register_email_help; },
);

has register_telephone_help => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->register_telephone_help; },
);

has register_organisation_help => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->register_organisation_help; },
);

has register_notes_help => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->register_notes_help; },
);

has global_view_summary => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_global_view_summary
{   my $self = shift;
    my @views = $self->schema->resultset('View')->search({
        -or => [
            global   => 1,
            is_admin => 1,
        ],
        instance_id => $self->id,
    },{
        order_by => 'me.name',
    })->all;
    \@views;
}

sub inflate_result {
    my $data   = $_[2];
    my $schema = $_[1]->schema;
    $_[0]->new(
        id                         => $data->{id},
        name                       => $data->{name},
        homepage_text              => $data->{homepage_text},
        homepage_text2             => $data->{homepage_text2},
        sort_layout_id             => $data->{sort_layout_id},
        sort_type                  => $data->{sort_type},
        register_title_help        => $data->{register_title_help},
        register_email_help        => $data->{register_email_help},
        register_telephone_help    => $data->{register_telephone_help},
        register_organisation_help => $data->{register_organisation_help},
        register_notes_help        => $data->{register_notes_help},
        schema                     => $schema,
    );
}

sub _build__rset
{   my $self = shift;
    my ($instance) = $self->schema->resultset('Instance')->search({
        'me.id' => $self->id,
    })->all;
    $instance;
}

sub write
{   my $self = shift;
    my $values = {
        name                       => $self->name,
        homepage_text              => $self->homepage_text,
        homepage_text2             => $self->homepage_text2,
        sort_layout_id             => $self->sort_layout_id,
        sort_type                  => $self->sort_type,
        register_title_help        => $self->register_title_help,
        register_email_help        => $self->register_email_help,
        register_telephone_help    => $self->register_telephone_help,
        register_organisation_help => $self->register_organisation_help,
        register_notes_help        => $self->register_notes_help,
    };
    if ($self->id)
    {
        $self->_rset->update($values);
    }
    else {
        $self->_set__rset($self->schema->resultset('Instance')->create($values));
        $self->_set_id($self->_rset->id);
    }
}

sub as_string
{   my $self = shift;
    $self->name;
}

sub as_integer
{   my $self = shift;
    $self->id;
}

1;
