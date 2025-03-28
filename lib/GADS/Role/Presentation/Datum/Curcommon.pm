package GADS::Role::Presentation::Datum::Curcommon;

use Moo::Role;

sub _presentation_details {
    my ($self, %options) = @_;

    #return [] unless $self->as_string;

    my $rti = $self->column->refers_to_instance_id;

    my @values = $options{values} ? @{$options{values}} : @{$self->values};

    my @links = map +{
        id                    => $_->{id},
        href                  => $_->{value},
        refers_to_instance_id => $rti,
        values                => $_->{values},
        presentation          => $_->{record}->presentation(curval_fields => $self->column->curval_fields),
        status                => $_->{status}, # For chronological view
        version_id            => $_->{version_id}, # For chronological view
    }, @values;

    return \@links;
}

sub presentation {
    my ($self, %options) = @_;

    my $multivalue = $self->column->multivalue;

    my $base = $self->presentation_base;

    $base->{text}    = $base->{value};
    $base->{id_hash} = $self->id_hash;
    $base->{links}   = $self->_presentation_details(%options);
    if ($self->column->value_selector eq 'typeahead' && !$multivalue)
    {
        # Currently autocomplete textboxes can only be single value. May want to
        # change this in the future.
        #
        # If this is a draft record, then the query should be used instead of
        # the ID. The query will only exist if it's a draft record
        if ($self->column->show_add)
        {
            if (my $q = $self->html_form->[0] && $self->html_form->[0]->{as_query})
            {
                $base->{autocomplete_value} = $q;
            }
            else {
                $base->{autocomplete_value} = $self->id;
            }
        }
        else {
            $base->{autocomplete_value} = $self->id;
        }
    }

    # Function to return the values for the drop-down selector, but only the
    # selected ones. This makes rendering the edit page quicker, as in the case of
    # a filtered drop-down, the values will be fetched each time it gets the
    # focus anyway
    $base->{selected_values} = [
        map { $self->column->_format_row($_->{record}) } @{$self->values}
    ];

    # The name used in the URL to access the parent table
    $base->{parent_layout_identifier} = $self->column->layout_parent->identifier,

    $base->{has_more} = $self->has_more;

    return $base;
}

1;
