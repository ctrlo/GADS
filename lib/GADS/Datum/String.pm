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

package GADS::Datum::String;

use HTML::FromText;
use Log::Report 'linkspace';
use Moo;
use namespace::clean;

extends 'GADS::Datum';

sub set_value
{   my ($self, $value) = @_;
    ($value) = @$value if ref $value eq 'ARRAY';
    $value =~ /\h+$/ if !ref $value && $value;
    if (my $regex = !ref $value && $self->column->force_regex)
    {
        my $msg = __x"Invalid value \"{value}\" for {field}", value => $value, field => $self->column->name;
        # Empty values are not checked - these should be done in optional value for field
        if ($value && $value !~ /^$regex$/)
        {
            # Changed code repeated below, but don't want to flag changed if
            # resulting error
            ($self->value || '') ne ($value || '') ? error($msg) : warning($msg);
        }
    }
    $self->changed(1)
        if ($self->value || '') ne ($value || '');
    $self->_set_written_valid(!!$value);
    $self->oldvalue($self->clone);
    $self->value($value);
    $self->_set_written_to(0) if $self->value_next_page;
}

has value => (
    is        => 'rw',
    lazy      => 1,
    trigger   => sub {
        $_[0]->blank(length $_[1] ? 0 : 1)
    },
    builder   => sub {
        my $self = shift;
        $self->has_init_value or return;
        my $value = $self->init_value->[0]->{value};
        $self->has_value(1) if defined $value || $self->init_no_value;
        $value;
    },
);

sub _build_blank {
    length $_[0]->value ? 0 : 1;
}

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self, value => $self->value, @_);
};

sub as_string
{   my $self = shift;
    $self->value // "";
}

sub as_integer
{   my $self = shift;
    no warnings 'numeric';
    int ($self->value // 0);
}

sub html_withlinks
{   my $self = shift;
    my $string = $self->as_string;
    text2html(
        $string,
        urls      => 1,
        email     => 1,
        metachars => 1,
    );
}

1;

