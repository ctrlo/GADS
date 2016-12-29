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

package GADS::Datum::Rag;

use Log::Report;
use Moo;
use namespace::clean;

extends 'GADS::Datum::Code';

has set_value => (
    is      => 'rw',
    trigger => sub {
        my $self = shift;
        $self->_set_has_value(1);
    },
);

has value => (
    is       => 'rw',
    lazy     => 1,
    clearer  => 1,
    builder  => sub {
        my $self = shift;
        $self->_transform_value($self->init_value);
    },
);

has has_value => (
    is => 'rwp',
);

has dependent_values => (
    is       => 'rw',
    required => 1,
);

has layout => (
    is       => 'rw',
    required => 1,
);

sub _transform_value
{   my ($self, $original) = @_;

    my $column           = $self->column;
    my $layout           = $self->layout;
    my $dependent_values = $self->dependent_values;

    if (exists $original->{value} && !$self->force_update)
    {
        return $original->{value};
    }
    elsif (!$self->column->green && !$self->column->amber && !$self->column->red)
    {
        return $self->_write_rag('a_grey');
    }
    else {
        # Used during tests to check that $original is being set correctly
        panic "Entering calculation code"
            if $ENV{GADS_PANIC_ON_ENTERING_CODE};

        my $green = $self->column->green;
        my $amber = $self->column->amber;
        my $red   = $self->column->red;

        foreach my $col_id (@{$column->depends_on})
        {
            my $col = $layout->column($col_id);
            $green  = $self->sub_values($col, $green);
            $amber  = $self->sub_values($col, $amber);
            $red    = $self->sub_values($col, $red);
            defined $green && defined $amber && defined $red
                or return $self->_write_rag('a_grey');
        }

        # Insert current date if required
        $green = $self->sub_date($green, 'CURDATE', DateTime->now->truncate(to => 'day'));
        $amber = $self->sub_date($amber, 'CURDATE', DateTime->now->truncate(to => 'day'));
        $red   = $self->sub_date($red, 'CURDATE', DateTime->now->truncate(to => 'day'));

        # Insert ID if required
        my $current_id = $self->current_id;
        $green =~ s/\[id\]/$current_id/ if $green;
        $amber =~ s/\[id\]/$current_id/ if $amber;
        $red   =~ s/\[id\]/$current_id/ if $red;

        my $okaycount = 0;
        foreach my $code ($green, $amber, $red)
        {
            # If there are still square brackets then something is wrong
            if ($code && $code =~ /[\[\]]+/)
            {
                warning __x"Invalid field names in rag condition. Remaining code: {code}", code => $code;
            }
            else {
                $okaycount++;
            }
        }

        my $ragvalue;
        # XXX Log somewhere if this fails
        if ($okaycount == 3)
        {
            trace __x"Red code is: {red}", red => $red;
            trace __x"Amber code is: {amber}", amber => $amber;
            trace __x"Green code is: {green}", green => $green;
            if (defined $red && try { $self->safe_eval("($red)") } )
            {
                $ragvalue = 'b_red';
            }
            elsif (!$@ && defined $amber && try { $self->safe_eval("($amber)") } )
            {
                $ragvalue = 'c_amber';
            }
            elsif (!$@ && defined $green && try { $self->safe_eval("($green)") } )
            {
                $ragvalue = 'd_green';
            }
            elsif ($@) {
                # An exception occurred evaluating the code
                $ragvalue = 'e_purple';
                my $error = $@->wasFatal->message->toString;
                warning __x"Failed to eval rag. Code was: {error}", error => $error;
            }
            else {
                $ragvalue = 'a_grey';
            }
        }
        else {
            $ragvalue = 'e_purple';
        }
        return $self->_write_rag($ragvalue);
    }
}

sub _write_rag
{   my $self = shift;
    $self->write_cache('ragval', @_);
}

# XXX Why is this needed? Error when creating new record otherwise
sub as_integer
{   my $self = shift;
    !$self->value
        ? 0
        : $self->value eq 'a_grey'
        ? 1
        : $self->value eq 'b_red'
        ? 2
        : $self->value eq 'c_amber'
        ? 3
        : $self->value eq 'd_green'
        ? 4
        : $self->value eq 'e_purple'
        ? -1
        : -2;
}

sub as_string
{   my $self = shift;
    $self->value // "";
}

sub equal
{   my ($self, $a, $b) = @_;
    $a eq $b;
}

1;

