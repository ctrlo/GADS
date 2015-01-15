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

use Scalar::Util qw(looks_like_number);
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
            my $col   = $layout->column($col_id);
            my $name  = $col->name;
            my $value = $self->dependent_values->{$col_id};

            if ($col->type eq "date")
            {
                $value = $value->value->epoch if $col->type eq "date";
            }
            elsif ($col->type eq "daterange")
            {
                $value = {
                    from => $value->from_dt ? $value->from_dt->epoch : undef,
                    to   => $value->to_dt   ? $value->to_dt->epoch   : undef,
                };
            }

            # If field is numeric but does not have numeric value, then return
            # grey, otherwise the value will be treated as zero
            # and will probably return misleading RAG values
            if ($col->numeric)
            {
                if (
                       ($col->type eq "daterange" && (!$value->{from} || !$value->{to}))
                    ||  $col->type ne "daterange" && !looks_like_number $value
                )
                {
                    return $self->_write_rag('a_grey');
                }
            }

            if ($col->type eq "daterange")
            {
                $green =~ s/\[$name\.from\]/$value->{from}/gi;
                $green =~ s/\[$name\.to\]/$value->{to}/gi;
                $amber =~ s/\[$name\.from\]/$value->{from}/gi;
                $amber =~ s/\[$name\.to\]/$value->{to}/gi;
                $red   =~ s/\[$name\.from\]/$value->{from}/gi;
                $red   =~ s/\[$name\.to\]/$value->{to}/gi;
            }
            else {
                unless($col->{numeric})
                {
                    $value = $value ? $value->as_string : "";
                    $value = "\"$value\"";
                }
                $green =~ s/\[$name\]/$value/gi;
                $amber =~ s/\[$name\]/$value/gi;
                $red   =~ s/\[$name\]/$value/gi;
            }
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
            $ragvalue = 'a_grey';
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

