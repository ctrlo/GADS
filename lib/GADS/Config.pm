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

package GADS::Config;

use Log::Report;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has schema => (
    is       => 'rw',
    required => 1,
);

has homepage_text => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_conf->homepage_text;
    },
);

has homepage_text2 => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_conf->homepage_text2;
    },
);

has sort_layout_id => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    coerce  => sub { $_[0]||undef },
    builder => sub {
        my $self = shift;
        $self->_conf->sort_layout_id;
    },
);

has sort_type => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_conf->sort_type;
    },
);

has register_title_help => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_conf->register_title_help;
    },
);

has register_email_help => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_conf->register_email_help;
    },
);

has register_telephone_help => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_conf->register_telephone_help;
    },
);

has register_organisation_help => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_conf->register_organisation_help;
    },
);

has register_notes_help => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_conf->register_notes_help;
    },
);

has _conf => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my ($conf) = $self->schema->resultset('Instance')->search->all;
        $conf;
    },
);

sub write
{   my $self = shift;
    my $new = {
        homepage_text  => $self->homepage_text,
        homepage_text2 => $self->homepage_text2,
        sort_layout_id => $self->sort_layout_id,
        sort_type      => $self->sort_type,
    };

    $self->_conf->update($new);
}

1;

