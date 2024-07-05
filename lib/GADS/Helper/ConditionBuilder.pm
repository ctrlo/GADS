use utf8;

package GADS::Helper::ConditionBuilder;

use strict;
use warnings;

use Log::Report 'linkspace';
use Moo::Role;

with 'MooX::Singleton';

sub _escape_like
{   my ($self, $string) = @_;
    $string =~ s!\\!\\\\!;
    $string =~ s/%/\\%/;
    $string =~ s/_/\\_/;
    $string;
}

has field_map => (
    is      => 'ro',
    default => sub {
        return {
            equal            => "=",
            greater          => '>',
            greater_or_equal => '>=',
            less             => '<',
            less_or_equal    => '<=',
            not_equal        => "!=",
            begins_with      => "-like",
            not_begins_with  => '-not_like',
            ends_with        => "-like",
            contains         => "-like",
            not_contains     => "-not_like",
            is_empty         => "=",
            is_not_empty     => "!="
        };
    },
);

sub get_filter_value
{   my ($self, $filter_operator, $value, $is_number) = @_;

    return $value if $is_number;

    if (lc $filter_operator eq 'begins_with')
    {
        $value = $self->_escape_like($value);
        return "$value%";
    }
    elsif (lc $filter_operator eq 'not_begins_with')
    {
        $value = $self->_escape_like($value);
        return "$value%";
    }
    elsif (lc $filter_operator eq 'ends_with')
    {
        $value = $self->_escape_like($value);
        return "%$value";
    }
    elsif (lc $filter_operator eq 'contains')
    {
        $value = $self->_escape_like($value);
        return "%$value%";
    }
    elsif (lc $filter_operator eq 'not_contains')
    {
        $value = $self->_escape_like($value);
        return "%$value%";
    }
    else {
        return $value;
    }
}

sub filter_hook {}

sub map_rules
{   my ($self, $filter, %options) = @_;


    if (my $rules = $filter->{rules}) # Filter has other nested filters
    {
        # Allow different action to be taken to normal using hook
        my $hook_result = $self->filter_hook($filter);
        return $hook_result if $hook_result;

        my @final;
        foreach my $rule (@$rules)
        {
            my @res = $self->map_rules($rule, %options);
            push @final, @res if @res;
        }
        my $condition = $filter->{condition} && $filter->{condition} eq 'OR' ? '-or' : '-and';
        return @final ? ($condition => \@final) : ();
    }
    elsif (%$filter)
    {
        return $self->rule_to_condition($filter, %options);
    }
    else {
        return;
    }
}

1;
