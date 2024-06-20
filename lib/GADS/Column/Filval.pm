
=pod
GADS - Globally Accessible Data Store
Copyright (C) 2019 Ctrl O Ltd

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

package GADS::Column::Filval;

use GADS::Records;
use Log::Report 'linkspace';

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

with 'GADS::Role::Curcommon::RelatedField';
with 'GADS::Role::Curcommon::CurvalMulti';

extends 'GADS::Column::Curcommon';

has '+multivalue' => (coerce => sub { 1 },);

has '+userinput' => (default => 0,);

has '+table' => (default => 'Curval',);

# Same as Column::Curval
sub make_join
{   my ($self, @joins) = @_;
    return $self->field
        if !@joins;
    +{
        $self->field => {
            value => {
                record_single => [ 'record_later', @joins ],
            }
        }
    };
}

sub write_special
{   my ($self, %options) = @_;

    return if $options{override};

    my $rset = $options{rset};

    $self->related_field_id
        or error __x "Please select a field to store the filtered values from";

    $rset->update({
        related_field => $self->related_field_id,
    });

    $self->_update_curvals(%options);

    # Clear what may be cached values that should be updated after write
    $self->clear;

    return ();
}

sub _build_refers_to_instance_id
{   my $self = shift;
    $self->related_field or return undef;
    $self->related_field->refers_to_instance_id;
}

# Filvals are defined as not user input, so they get updated during
# update-cached. This makes sure that it does nothing silently
sub update_cached { }

# Not applicable for filvals - there is no filtering for an autocur column as
# there is with curvals
sub filter_view_is_ready
{   my $self = shift;
    return 1;
}

has view => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub { },
);

around export_hash => sub {
    my $orig    = shift;
    my $self    = shift;
    my %options = @_;
    my $hash    = $orig->($self, @_);
    $hash->{related_field_id} = $self->related_field_id;
    $hash;
};

around import_after_all => sub {
    my $orig = shift;
    my ($self, $values, %options) = @_;
    my $mapping = $options{mapping};
    my $report  = $options{report_only};
    my $new_id  = $mapping->{ $values->{related_field_id} };
    notice __x "Update: related_field_id from {old} to {new}",
        old => $self->related_field_id,
        new => $new_id
        if $report && $self->related_field_id != $new_id;
    $self->related_field_id($new_id);
    $orig->(@_);
};

1;
