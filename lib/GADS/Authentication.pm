=pod
GADS - Globally Accessible Data Store
Copyright (C) 2024 Ctrl O Ltd

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

package GADS::Authentication;

use GADS::Email;
use GADS::Util;
use Log::Report 'linkspace';
use POSIX ();
use Scope::Guard qw(guard);

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has schema => (
    is       => 'ro',
    required => 1,
);

has all => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub authentication_rs
{   my $self = shift;
    $self->schema->resultset('Authentication')->providers;
}

sub authentication_summary_rs
{   my $self = shift;
    my $summary = $self->authentication_rs->search_rs({},{
        columns => [
                'me.id', 'me.site_id', 'me.type', 'me.name', 'me.enabled', 'me.error_messages',
                #FIXME remove 'me.xml', 'me.sp_key',
        ],
        order_by => 'name',
        collapse => 1,
    });
    return $summary;
}

sub _build_all
{   my $self = shift;
    my @authentication = $self->authentication_summary_rs->all;
    \@authentication;
}

1;
