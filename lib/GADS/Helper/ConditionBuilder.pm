use utf8;

package GADS::Helper::ConditionBuilder;

use strict;
use warnings;

use Moo;

use Data::Dumper;

with 'MooX::Singleton';

has fieldMap => (
    is      => 'ro',
    default => sub {
        return {
            equal        => "=",
            not_equal    => "!=",
            begins_with  => "-like",
            ends_with    => "-like",
            contains     => "-like",
            not_contains => "-notlike",
            is_empty     => "=",
            is_not_empty => "!="
        };
    },
);

sub getFieldValue {
    my ( $self, $field, $value ) = @_;

    if ( lc $field eq 'equal' ) {
        return $value;
    }
    elsif ( lc $field eq 'not_equal' ) {
        return $value;
    }
    elsif ( lc $field eq 'begins_with' ) {
        return $value . '%';
    }
    elsif ( lc $field eq 'ends_with' ) {
        return '%' . $value;
    }
    elsif ( lc $field eq 'contains' ) {
        return '%' . $value . '%';
    }
    elsif ( lc $field eq 'not_contains' ) {
        return '%' . $value . '%';
    }
    elsif ( lc $field eq 'is_empty' ) {
        return;
    }
    elsif ( lc $field eq 'is_not_empty' ) {
        return;
    }
    else {
        print STDERR "Unknown field: $field\n";
        return;
    }
}

sub map {
    my ( $self, $input ) = @_;

    my %result;
    my $condition = "-" . lc( $input->{condition} );
    $result{$condition} = {};

    $self->mapRules( $input->{rules}, $result{$condition} );

    return \%result;
}

sub mapRules {
    my ( $self, $rules, $result ) = @_;

    foreach my $rule (@$rules) {
        if ( exists $rule->{condition} ) {
            my $condition = "-" . lc( $rule->{condition} );
            $result->{$condition} = {};
            $self->mapRules( $rule->{rules}, $result->{$condition} );
            next;
        }

        my ( $field, $operator, $value ) =
          ( $rule->{field}, $rule->{operator}, $rule->{value} );
        my $mappedOperator = $self->fieldMap->{$operator};
        my $mappedValue    = $self->getFieldValue( $operator, $value );

        $result->{$field} //= {};
        $result->{$field}{$mappedOperator} //= $mappedValue;
        if ( ref( $result->{$field}{$mappedOperator} ) eq 'ARRAY' ) {
            push @{ $result->{$field}{$mappedOperator} }, $mappedValue;
        }
        else {
            if ( $result->{$field}{$mappedOperator} ne $mappedValue ) {
                $result->{$field}{$mappedOperator} =
                  [ $result->{$field}{$mappedOperator}, $mappedValue ];
            }
        }
    }
}

1;
