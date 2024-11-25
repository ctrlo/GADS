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

package GADS::DateTime;

use DateTime::Format::CLDR;
use DateTime::Span;
use GADS::Config;
use Log::Report 'linkspace';
use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);

sub date_as_epoch {
    my ($self, $value) = @_;
    my $date = GADS::DateTime::parse_datetime($value);
    return $date && $date->epoch;
}

sub parse_datetime
{   my $value = shift;
    return undef if !$value;
    return $value if ref $value eq 'DateTime';
    my $dateformat = GADS::Config->instance->dateformat;
    # If there's a space in the input value, assume it includes a time as well
    $dateformat .= ' HH:mm:ss' if $value =~ / /;
    my $cldr = DateTime::Format::CLDR->new(
        pattern => $dateformat,
    );
    $value && $cldr->parse_datetime($value);
}

sub parse_daterange
{   my ($self, $original, %options) = @_;
    my $source = $options{source};

    $original or return;

    # Array ref will be received from form
    if (ref $original eq 'ARRAY')
    {
        $original = {
            from => $original->[0],
            to   => $original->[1],
        };
    }
    elsif (!ref $original)
    {
        # XXX Nasty hack. Would be better to pull both values from DB
        $original =~ /^([-0-9]+) to ([-0-9]+)$/;
        $original = {
            from => $1,
            to   => $2,
        };
    }

    # Otherwise assume it's a hashref: { from => .., to => .. }

    if (!$original->{from} && !$original->{to})
    {
        return;
    }

    my ($from, $to);
    if ($source eq 'db')
    {
        my $db_parser = $self->schema->storage->datetime_parser;
        my $f = $original->{from};
        $f = "$f 00:00:00" if $f !~ / /;
        my $t = $original->{to};
        $t = "$t 00:00:00" if $t !~ / /;
        $from = $db_parser->parse_datetime($f);
        $to   = $db_parser->parse_datetime($t);
    }
    elsif (ref $original->{from} eq 'DateTime' && ref $original->{to} eq 'DateTime')
    {
        $from = $original->{from};
        $to   = $original->{to};
    }
    else { # Assume 'user'
        # If it's not a valid value, see if it's a duration instead (only for bulk)
        if ($self->column->validate($original, fatal => !$options{bulk}))
        {
            $from = $self->column->parse_date($original->{from});
            $to   = $self->column->parse_date($original->{to});
        }
        elsif($options{bulk}) {
            my $from_duration = DateTime::Format::DateManip->parse_duration($original->{from});
            my $to_duration = DateTime::Format::DateManip->parse_duration($original->{to});
            if ($from_duration || $to_duration)
            {
                if (@{$self->values})
                {
                    my @return;
                    foreach my $value (@{$self->values})
                    {
                        $from = $value->start;
                        $from->add_duration($from_duration) if $from_duration;
                        $to = $value->end;
                        $to->add_duration($to_duration) if $to_duration;
                        push @return, DateTime::Span->from_datetimes(start => $from, end => $to);
                    }
                    return @return;
                }
                else {
                    return; # Don't bork as we might be bulk updating, with some blank values
                }
            }
            else {
                # Nothing fits, raise fatal error
                $self->column->validate($original, fatal => 1);
            }
        }
    }

    $to->subtract( days => $options{subtract_days_end} ) if $options{subtract_days_end};
    (DateTime::Span->from_datetimes(start => $from, end => $to));
}

sub date_as_string
{   my ($self, $value, $format) = @_;
    $value or return '';
    $format or panic "Missing format for date_as_string";
    $value->clone->set_time_zone('Europe/London')->format_cldr($format);
}

sub daterange_as_string
{   my ($self, $value, $format) = @_;
    $value or return '';
    $format or panic "Missing format for daterange_as_string";
    my $start = $value->start->clone->set_time_zone('Europe/London');
    my $end   = $value->end->clone->set_time_zone('Europe/London');
    $start->format_cldr($format) . " to " . $end->format_cldr($format);
}

sub validate_daterange
{   my ($self, $value, %options) = @_;

    return 1 if !$value;
    return 1 if !$value->{from} && !$value->{to};

    if ($value->{from} xor $value->{to})
    {
        return 0 unless $options{fatal};
        error __x"Please enter 2 date values for '{col}'", col => $self->name;
    }
    my $from;
    if ($value->{from} && !($from = $self->parse_date($value->{from})))
    {
        return 0 unless $options{fatal};
        error __x"Invalid start date {value} for {col}. Please enter as {format}.",
            value => $value->{from}, col => $self->name, format => $self->dateformat;
    }
    my $to;
    if ($value->{to} && !($to = $self->parse_date($value->{to})))
    {
        return 0 unless $options{fatal};
        error __x"Invalid end date {value} for {col}. Please enter as {format}.",
            value => $value->{to}, col => $self->name, format => $self->dateformat;
    }

    if (DateTime->compare($from, $to) == 1)
    {
        return 0 unless $options{fatal};
        error __x"Start date must be before the end date for '{col}'", col => $self->name;
    }

    1;
}

sub validate_daterange_search
{   my ($self, $value, %options) = @_;
    return 1 if !$value;
    if ($options{single_only})
    {
        return 1 if $self->parse_date($value);
        return 0 unless $options{fatal};
        error __x"Invalid single date format {value} for {name}",
            value => $value, name => $self->name;
    }
    if ($options{full_only})
    {
        if (my $hash = $self->split($value))
        {
            return $self->validate($hash, %options);
        }
        # Unable to split
        return 0 unless $options{fatal};
        my $config = GADS::Config->instance;
        error __x"Invalid full date format {value} for {name}. Please enter as {format}.",
            value => $value, name => $self->name, format => $config->dateformat;
    }
    # Accept both formats. Normal date format used to validate searches
    return 1 if $self->parse_date($value) || ($self->split($value) && $self->validate($self->split($value)));
    return 0 unless $options{fatal};
    error "Invalid format {value} for {name}",
        value => $value, name => $self->name;
}

sub split
{   my ($self, $value) = @_;
    if ($value =~ /(.+) to (.+)/)
    {
        my $from = $1; my $to = $2;
        $self->parse_date($from) && $self->parse_date($to)
            or return;
        return {
            from => $from,
            to   => $to,
        };
    }
}

1;

