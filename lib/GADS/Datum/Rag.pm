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

use Moo;
use namespace::clean;

use overload '""' => \&as_string;

extends 'GADS::Datum::Code';

has set_value => (
    is       => 'rw',
);

has value => (
    is       => 'rw',
    lazy     => 1,
    builder => sub {
        my $self = shift;
        $self->_transform_value($self->set_value);
    },
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
        my $green = $self->column->green;
        my $amber = $self->column->amber;
        my $red   = $self->column->red;

        foreach my $col_id (@{$column->depends_on})
        {
            my $col = $layout->column($col_id);
            $green  = $self->sub_values($col, $green);
            $amber  = $self->sub_values($col, $amber);
            $red    = $self->sub_values($col, $red);
            $green && $amber && $red or return $self->_write_rag('a_grey');
        }

        # Insert current date if required
        my $now = time;
        $green =~ s/CURDATE/$now/g;
        $amber =~ s/CURDATE/$now/g;
        $red   =~ s/CURDATE/$now/g;

        # Insert ID if required
        my $current_id = $self->current_id;
        $green =~ s/\[id\]/$current_id/;
        $amber =~ s/\[id\]/$current_id/;
        $red   =~ s/\[id\]/$current_id/;

        my $okaycount = 0;
        foreach my $code ($green, $amber, $red)
        {
            # If there are still square brackets then something is wrong
            $okaycount++ if $code !~ /[\[\]]+/;
        }

        my $ragvalue;
        # XXX Log somewhere if this fails
        if ($okaycount == 3)
        {
            if ($red && eval { $self->safe_eval("($red)") } )
            {
                $ragvalue = 'b_red';
            }
            elsif (!$@ && $amber && eval { $self->safe_eval("($amber)") } )
            {
                $ragvalue = 'c_amber';
            }
            elsif (!$@ && $green && eval { $self->safe_eval("($green)") } )
            {
                $ragvalue = 'd_green';
            }
            elsif ($@) {
                # An exception occurred evaluating the code
                $ragvalue = 'e_purple';
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

sub as_string
{   my $self = shift;
    $self->value // "";
}

1;

