use utf8;

package GADS::PeopleFilter;

use strict;
use warnings;

use Moo;
use Log::Report 'linkspace';
use Encode;
use MIME::Base64;

extends 'GADS::Filter';

sub base64 {
    my $self = shift;
    foreach my $filter ( @{ $self->filters } ) {
        $self->layout or panic "layout has not been set in filter";
        my $col = $self->layout->column( $filter->{column_id} )
          or next;    # Ignore invalid - possibly since deleted
                      # Next update the filters
        if ( $col->has_filter_typeahead ) {
            $filter->{data} =
              { text => $col->filter_value_to_text( $filter->{value} ), };
        }
        if ( $col->type eq 'filval' ) {
            $filter->{filtered} = $col->related_field_id,;
        }
    }

    # Now the JSON version will be built with the inserted data values
    encode_base64( $self->as_json, '' ); # Base64 plugin does not like new lines
}

has person_filter => ( is => 'lazy', );

sub _build_person_filter {
    my $self = shift;

    return GADS::Helper::ConditionBuilder->instance->map( $self->as_hash );
}

1;
