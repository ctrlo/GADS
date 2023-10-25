
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

package GADS::Report;

use Data::Dumper;
use Log::Report 'linkspace';
use Safe;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

use Dancer2;
use Dancer2::Plugin::DBIC;

has id => (
    is       => 'ro',
    required => 1,
);

has name => (
    is       => 'rw',
    required => 0,
);

has description => (
    is       => 'rw',
    required => 0,
);

has user_id => (
    is       => 'rw',
    required => 0,
);

has user => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my $user = schema->resultset('User')->find( $self->user_id );
        return $user;
    }
);

has createdby => (
    is       => 'rw',
    required => 0,
);

has createdby_user => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        if ( $self->createdby ) {
            my $user = schema->resultset('User')->find( $self->createdby );
            return $user;
        }
        return $self->user;
    },
);

has created => (
    is       => 'rw',
    required => 0,
);

has instance_id => (
    is       => 'rw',
    required => 0,
);

has instance => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my $instance =
          schema->resultset('Instance')->find( $self->instance_id )->single;
        return $instance;
    },
);

has layout_ids => (
    is       => 'rw',
    required => 0,
);

has layouts => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my @layouts;
        if ( $self->layout_ids ) {
            @layouts = map {
                print STDOUT "Loading layout $_\n";
                schema->resultset('Layout')->search( { id => $_ } )
            } @{ $self->layout_ids };
        }
        return \@layouts;
    },
);

sub load_all_reports {
    my $instance_id = shift;

    die "Invalid layout provided"
      unless $instance_id && $instance_id =~ /^\d+$/;

    my $reports = schema->resultset('Report')->search(
        {
            instance_id => $instance_id,
        }
    );

    my @result;

    while ( my $next = $reports->next ) {
        my $report = GADS::Report->new(
            id          => $next->id,
            name        => $next->name,
            description => $next->description,
            user_id     => $next->user_id,
            createdby   => $next->createdby->id,
            instance_id => $next->instance_id,
            created => DateTime::Format::Pg->parse_datetime( $next->created ),
        );
        my $layouts = schema->resultset('ReportLayout')->search(
            {
                report_id => $next->id,
            }
        );
        while ( my $layout = $layouts->next ) {
            $report->add_layout( $layout->layout_id );
        }
        push( @result, $report );
    }

    return \@result;
}

sub add_layout {
    my $self      = shift;
    my $layout_id = shift;
    print STDOUT "Adding layout $layout_id\n";
    print STDOUT Dumper $self->layout_ids;
    print STDOUT "\n";

    die "You aren't doing it right" unless ref($self) eq __PACKAGE__;
    die "No layout id provided"     unless $layout_id;

    if ( !$self->layout_ids ) {
        $self->layout_ids( [] );
    }

    push @{ $self->layout_ids }, $layout_id;
}

sub load {
    my $self = shift;

    print STDOUT "Loading " . $self->id . "\n";

    #assume I'm going to make a mistake some time!
    die "You aren't doing it right" unless ref($self) eq __PACKAGE__;
    die "No report id provided"     unless $self->id && $self->id =~ /^\d+$/;

    my $report = schema->resultset('Report')->find( $self->id );

    die "No report found" unless $report;

    print STDOUT "Loading report " . $report->name . "\n";

    $self->name( $report->name );
    $self->description( $report->description );
    $self->user_id( $report->user_id );
    $self->createdby( $report->createdby->id );
    $self->instance_id( $report->instance_id );
    $self->created( DateTime::Format::Pg->parse_datetime( $report->created ) );

    my $layouts = schema->resultset('ReportLayout')->search(
        {
            report_id => $self->id,
        }
    );
    while ( my $layout = $layouts->next ) {
        $self->add_layout( $layout->layout_id );
    }
}

sub render_report {

    #TODO: render report method
}

1;
