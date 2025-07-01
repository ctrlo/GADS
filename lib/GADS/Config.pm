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

use Log::Report 'linkspace';
use Path::Class qw(dir);
use Moo;

with 'MooX::Singleton';

has config => (
    is       => 'rw',
    required => 1,
    trigger  => sub {
        my $self = shift;
        $self->clear_gads;
        $self->clear_login_instance;
        $self->clear_dateformat;
        $self->clear_dateformat_datepicker;
        $self->clear_uploads;
    },
);

has app_location => (
    is => 'ro',
);

has template_location => (
    is => 'lazy',
);

sub _build_template_location
{   my $self = shift;
    dir($self->app_location || '.', "views");
}

has gads => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub { ref $_[0]->config eq 'HASH' && $_[0]->config->{gads} },
);

has login_instance => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub { $_[0]->gads->{login_instance} || 1 },
);

has url => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        my $url = ref $self->gads eq 'HASH' && $self->gads->{url}
            or panic "URL not configured";
        $url =~ s!/$!!; # Remove trailing slash
        $url;
    },
);

has dateformat => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        ref $self->gads eq 'HASH' && $self->gads->{dateformat} || 'yyyy-MM-dd';
    },
);

has dateformat_datepicker => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        my $dateformat = $self->dateformat;
        # Convert CLDR to datepicker.
        # Datepicker accepts:
        # d, dd: Numeric date, no leading zero and leading zero, respectively. Eg, 5, 05.
        # - No change required
        # D, DD: Abbreviated and full weekday names, respectively. Eg, Mon, Monday.
        $dateformat =~ s/eeee/DD/;
        $dateformat =~ s/eee/D/;
        # m, mm: Numeric month, no leading zero and leading zero, respectively. Eg, 7, 07.
        $dateformat =~ s/MM(?!M)/mm/;
        $dateformat =~ s/M(?!M)/m/;
        # M, MM: Abbreviated and full month names, respectively. Eg, Jan, January
        $dateformat =~ s/MMMM/MM/;
        $dateformat =~ s/MMM/M/;
        # yy, yyyy: 2- and 4-digit years, respectively. Eg, 12, 2012.
        # - No change required

        return $dateformat;
    },
);

has uploads => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        my $upload_path = (ref($self->gads) eq 'HASH' && $self->gads->{uploads}) || '/var/lib/GADS/uploads';
        $upload_path =~ s!/$!!; # Remove leading slash
        error __x"Upload directory {path} does not exist", path => $upload_path
            unless -d $upload_path;
        $upload_path;
    }
);

1;
