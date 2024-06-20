
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

# Class to provide descriptions for email alerts
package GADS::AlertDescription;

use GADS::Layout;
use GADS::Records;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has schema => (
    is       => 'ro',
    required => 1,
);

has _cache => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { +{} },
);

sub alert_columns
{   my ($self, $instance_id) = @_;
    my $columns = $self->_alert_columns_cache->{$instance_id};
    return $columns if $columns;
    local $GADS::Schema::IGNORE_PERMISSIONS = 1;
    my $layout = GADS::Layout->new(
        instance_id => $instance_id,
        user        => undef,
        schema      => $self->schema,
    );
    $columns = [ $layout->alert_columns ];
    $self->_alert_columns_cache->{$instance_id} = $columns;
    return $columns;
}

has _alert_columns_cache => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { +{} },
);

sub only_id
{   my ($self, $instance_id) = @_;
    my $columns = $self->alert_columns($instance_id);
    return 1 if @$columns == 1 && $columns->[0]->name_short eq '_id';
    return 0;
}

sub descriptions
{   my ($self, %params) = @_;
    my $instance_id = $params{instance_id};
    my $current_ids = $params{current_ids};
    my $user        = $params{user};

    my @current_ids = ref $current_ids ? @$current_ids : ($current_ids);

    my @descriptions;

    foreach my $current_id (@current_ids)
    {
        if (my $cache = $self->_cache->{ $user->id }->{$current_id})
        {
            push @descriptions, $cache;
            next;
        }

        my $columns = $self->alert_columns($instance_id);

        my $description;
        if ($self->only_id($instance_id))
        {
            $description = $current_id;
        }
        else
        {
            my $column_ids = [ map $_->id, @$columns ];

            # Has the record since been deleted?
            if ($self->schema->resultset('Current')->find($current_id)->deleted)
            {
                $description = '[record deleted]';
            }
            else
            {
                my $record = GADS::Record->new(
                    user    => $user,
                    schema  => $self->schema,
                    columns => $column_ids,
                );
                $record->find_current_id($current_id);
                $description = join ', ', grep $_,
                    map $record->fields->{$_}->as_string,
                    grep $record->layout->column($_, permission => 'read'),
                    @$column_ids;
            }
        }

        $self->_cache->{ $user->id }->{$current_id} = $description;

        push @descriptions, $description;
    }

    return @descriptions;
}

sub join_delim
{   my ($self, $instance_id) = @_;
    $self->only_id($instance_id) ? ', ' : '; ';
}

sub description
{   my ($self, %params) = @_;
    my $instance_id  = $params{instance_id};
    my $current_ids  = $params{current_ids};
    my $user         = $params{user};
    my @descriptions = $self->descriptions(%params);
    my $desc         = join $self->join_delim($instance_id), @descriptions;
    $desc = @descriptions == 1 ? "record ID $desc" : "record IDs $desc"
        if $self->only_id($instance_id);
    return $desc;
}

sub link
{   my ($self, %params) = @_;
    my $instance_id  = $params{instance_id};
    my $current_ids  = $params{current_ids};
    my $user         = $params{user};
    my @descriptions = $self->descriptions(%params);
    my @current_ids  = ref $current_ids ? @$current_ids : ($current_ids);

    my $url    = GADS::Config->instance->url;
    my $prefix = '';
    if ($self->only_id($instance_id))
    {
        @descriptions = map "ID $_", @current_ids;
        $prefix       = @current_ids == 1 ? "record " : "records ";
    }
    my @links;
    foreach my $current_id (@current_ids)
    {
        my $description = shift @descriptions;
        push @links, qq(<a href="$url/record/$current_id">$description</a>);
    }
    return $prefix . join $self->join_delim($instance_id), @links;
}

1;

