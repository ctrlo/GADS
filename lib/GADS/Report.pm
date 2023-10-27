#TODO: This MOFO needs unit tests!! Talk to AB.

=pod
GADS - Globally Accessible Data Store
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

# package GADS::Report;

# use Data::Dumper;
# use Log::Report 'linkspace';
# use Safe;
# use Moo;
# use MooX::Types::MooseLike::Base qw(:all);
# use namespace::clean;

# use Dancer2;
# use Dancer2::Plugin::DBIC;

# has id => (
#     is       => 'ro',
#     required => 1,
# );

# has name => (
#     is       => 'rw',
#     required => 0,
# );

# has description => (
#     is       => 'rw',
#     required => 0,
# );

# has user_id => (
#     is       => 'rw',
#     required => 0,
# );

# has user => (
#     is      => 'rwp',
#     lazy    => 1,
#     builder => sub {
#         my $self = shift;
#         my $user = schema->resultset('User')->find( $self->user_id );
#         return $user;
#     }
# );

# has createdby => (
#     is       => 'rw',
#     required => 0,
# );

# has createdby_user => (
#     is      => 'rwp',
#     lazy    => 1,
#     builder => sub {
#         my $self = shift;
#         if ( $self->createdby ) {
#             my $user = schema->resultset('User')->find( $self->createdby );
#             return $user;
#         }
#         return $self->user;
#     },
# );

# has created => (
#     is       => 'rw',
#     required => 0,
# );

# has instance_id => (
#     is       => 'rw',
#     required => 0,
# );

# has instance => (
#     is      => 'rwp',
#     lazy    => 1,
#     builder => sub {
#         my $self = shift;
#         my $instance =
#           schema->resultset('Instance')->find( $self->instance_id );
#         return $instance;
#     },
# );

# has layout_ids => (
#     is       => 'rw',
#     required => 0,
# );

# has layouts => (
#     is      => 'rwp',
#     lazy    => 1,
#     builder => sub {
#         my $self = shift;
#         my @layouts;
#         if ( $self->layout_ids ) {
#             @layouts =
#               map { schema->resultset('Layout')->search( { id => $_ } ) }
#               @{ $self->layout_ids };
#         }
#         return \@layouts;
#     },
# );

# has report_id => (
#     is       => 'rw',
#     required => 0,
# );

# has data => (
#     is      => 'rwp',
#     lazy    => 1,
#     builder => sub {
#         my $self = shift;

#         my $result = [];

#         foreach my $layout ( @{ $self->layouts } ) {
#             my $data = $self->_load_record_data($layout);
#             push( @{$result}, $data );
#         }

#         return $result;
#     },
# );

# 1;
