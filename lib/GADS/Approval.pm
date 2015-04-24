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

package GADS::Approval;

use GADS::Datum::Person;
use Log::Report;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has schema => (
    is       => 'ro',
    required => 1,
);

has user => (
    is       => 'ro',
    required => 1,
);

has layout => (
    is => 'ro',
);

has records => (
    is  => 'lazy',
    isa => ArrayRef,
);

has _records => (
    is  => 'lazy',
    isa => HashRef,
);

has count => (
    is  => 'lazy',
    isa => Int,
);

sub _build_records
{   my $self = shift;
    [values %{$self->_records}];
}

sub _build__records
{   my $self = shift;

    # First short-cut and see if it is worth continuing
    return {} unless $self->schema->resultset('Record')->search({
        approval => 1,
    })->count;

    my $search = {
        'record.approval'          => 1,
        'layout_groups.permission' => 'approve_new',
        'user_id'                  => $self->user->{id},
        'record_previous.id'       => undef,
    };
    
    my $options = {
        join => [
            {
                'record' => {
                    'record' => 'record_previous',
                },
            },
            {
                'layout' => {
                    'layout_groups' => {
                        'group' => 'user_groups',
                    },
                },
            },
        ],
        prefetch => {'record' => 'createdby'},
        group_by => 'record.id',
        result_class => 'DBIx::Class::ResultClass::HashRefInflator',
    };

    my @records;

    if ($self->layout->user_can('approve_new'))
    {
        push @records, $self->schema->resultset('String')->search($search, $options)->all;
        push @records, $self->schema->resultset('Date')->search($search, $options)->all;
        push @records, $self->schema->resultset('Daterange')->search($search, $options)->all;
        push @records, $self->schema->resultset('Intgr')->search($search, $options)->all;
        push @records, $self->schema->resultset('Enum')->search($search, $options)->all;
        push @records, $self->schema->resultset('File')->search($search, $options)->all;
        push @records, $self->schema->resultset('Person')->search($search, $options)->all;
    }

    $search = {
        'record.approval'          => 1,
        'layout_groups.permission' => 'approve_existing',
        'user_id'                  => $self->user->{id},
        'record_previous.id'       => { '!=' => undef },
    };

    if ($self->layout->user_can('approve_existing'))
    {
        push @records, $self->schema->resultset('String')->search($search, $options)->all;
        push @records, $self->schema->resultset('Date')->search($search, $options)->all;
        push @records, $self->schema->resultset('Daterange')->search($search, $options)->all;
        push @records, $self->schema->resultset('Intgr')->search($search, $options)->all;
        push @records, $self->schema->resultset('Enum')->search($search, $options)->all;
        push @records, $self->schema->resultset('File')->search($search, $options)->all;
        push @records, $self->schema->resultset('Person')->search($search, $options)->all;
    }

    my $records = {};

    foreach my $record (@records)
    {
        my $record_id = $record->{record}->{id};
        next if $records->{$record_id};
        $records->{$record_id} = {
            record_id  => $record_id,
            current_id => $record->{record}->{current_id},
            createdby  => GADS::Datum::Person->new(
                record_id => $record->{record}->{id},
                set_value => {value => $record->{record}->{createdby}},
                schema    => $self->schema,
            ),
        };
    }

    $records;
}

sub _build_count
{   my $self = shift;
    scalar keys %{$self->_records};
}

1;

