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

package GADS::Datum::Daterange;

use DateTime;
use DateTime::Format::DateManip;
use DateTime::Span;
use GADS::SchemaInstance;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Datum';

has schema => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        GADS::SchemaInstance->instance;
    },
);

# Set datum value with value from user
sub set_value
{   my ($self, $all, %options) = @_;
    $all ||= [];
    my @all = @$all; # Take a copy first
    my $clone = $self->clone;
    shift @all if @all % 2 == 1 && !$all[0]; # First is hidden value from form
    my @values;
    $self->_set_written_valid(0) if !@values; # Assume 0, 1 written in parse_dt
    while (@all)
    {
        my @dt = $self->_parse_dt([shift @all, shift @all], source => 'user', %options);
        push @values, @dt if @dt;
    }
    my @text_all = sort map { $self->_as_string($_) } @values;
    my @old_texts = @{$self->text_all};
    my $changed = "@text_all" ne "@old_texts";
    if ($changed)
    {
        $self->changed(1);
        $self->_set_values([@values]);
        $self->_set_text_all([@text_all]);
        $self->clear_html_form;
        $self->clear_blank;
    }
    $self->oldvalue($clone);
    $self->_set_written_to(0) if $self->value_next_page;
}

has values => (
    is      => 'rwp',
    isa     => ArrayRef,
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->init_value or return [];
        my @values = map { $self->_parse_dt($_, source => 'db') } @{$self->init_value};
        $self->has_value(!!@values);
        [@values];
    },
);

has text_all => (
    is      => 'rwp',
    isa     => ArrayRef,
    lazy    => 1,
    builder => sub {
        my $self = shift;
        [ map { $self->_as_string($_) } @{$self->values} ];
    },
);

sub _build_blank
{   my $self = shift;
    ! grep { $_->start && $_->end } @{$self->values};
}

# Can't use predicate, as value may not have been built on
# second time it's set
has has_value => (
    is => 'rw',
);

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->(
        $self,
        values => $self->values,
        schema => $self->schema,
    );
};

sub _parse_dt
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
    # Otherwise assume it's a hashref: { from => .., to => .. }

    if (!$original->{from} && !$original->{to})
    {
        return;
    }

    my ($from, $to);
    if ($source eq 'db')
    {
        my $db_parser = $self->schema->storage->datetime_parser;
        $from = $db_parser->parse_date($original->{from});
        $to   = $db_parser->parse_date($original->{to});
    }
    else { # Assume 'user'
        # If it's not a valid value, see if it's a duration instead (only for bulk)
        if ($self->column->validate($original, fatal => !$options{bulk}))
        {
            $self->_set_written_valid(1);
            $from = $self->column->parse_date($original->{from});
            $to   = $self->column->parse_date($original->{to});
        }
        elsif($options{bulk}) {
            my $from_duration = DateTime::Format::DateManip->parse_duration($original->{from});
            my $to_duration = DateTime::Format::DateManip->parse_duration($original->{to});
            if ($from_duration || $to_duration)
            {
                $self->_set_written_valid(1);
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

# XXX Why is this needed? Error when creating new record otherwise
sub as_integer
{   my $self = shift;
    $self->value; # Force update of values
    $self->value && $self->value->start ? $self->value->start->epoch : 0;
}

sub as_string
{   my $self = shift;
    join ', ', @{$self->text_all};
}

sub _as_string
{   my ($self, $range) = @_;
    return "" unless $range;
    return "" unless $range->start && $range->end;
    my $format = $self->column->dateformat;
    $range->start->format_cldr($format) . " to " . $range->end->format_cldr($format);
}

has html_form => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_html_form
{   my $self = shift;
    [ map {
        $_->start->format_cldr($self->column->dateformat),
        $_->end->format_cldr($self->column->dateformat),
    } @{$self->values} ];
}

sub for_code
{   my $self = shift;
    return undef if !$self->column->multivalue && $self->blank;
    my @return = map {
        +{
            from  => $self->_date_for_code($_->start),
            to    => $self->_date_for_code($_->end),
            value => $self->_as_string($_),
        };
    } @{$self->values};

    $self->column->multivalue ? \@return : $return[0];
}

1;

