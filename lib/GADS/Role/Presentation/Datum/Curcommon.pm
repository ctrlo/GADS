package GADS::Role::Presentation::Datum::Curcommon;

use Moo::Role;

sub _presentation_details {
    my $self = shift;

    #return [] unless $self->as_string;

    my $rti = $self->column->refers_to_instance_id;

    my @links = map +{
        id                    => $_->{id},
        href                  => $_->{value},
        refers_to_instance_id => $rti,
        values                => $_->{values},
        presentation          => $_->{record}->presentation(curval_fields => $self->column->curval_fields),
    }, @{$self->values};

    return \@links;
}

sub presentation {
    my $self = shift;

    my $multivalue = $self->column->multivalue;

    my $base = $self->presentation_base;

    $base->{text}    = $base->{value};
    $base->{id_hash} = $self->id_hash;
    $base->{links}   = $self->_presentation_details;
    # Currently autocomplete textboxes can only be single value. May want to
    # change this in the future
    $base->{id}      = $self->id
        if $self->column->value_selector eq 'typeahead' && !$multivalue;

    # Function to return the values for the drop-down selector, but only the
    # selected ones. This makes rendering the edit page quicker, as in the case of
    # a filtered drop-down, the values will be fetched each time it gets the
    # focus anyway
    $base->{selected_values} = [
        map { $self->column->_format_row($_->{record}) } @{$self->values}
    ];

    return $base;
}

1;
