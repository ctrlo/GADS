package GADS::Role::Presentation::Column;

use Moo::Role;
use JSON qw(encode_json);
use URI::Escape qw/uri_escape_utf8/;

sub presentation {
    my ($self, %options) = @_;

    # data-values='[{"id": "23", "value": "Foo", "checked": true}, {"id": "24", "value": "Bar", "checked": true}]'

    my ($has_filter, @queries, @filter_values, $filter_text);
    foreach my $filter (@{$options{filters}})
    {
        if ($filter->{id} == $self->id)
        {
            $has_filter = 1;
            if ($self->fixedvals)
            {
                @filter_values = map {
                    +{
                        id      => $_,
                        value   => $self->id_as_string($_),
                        checked => \1,
                    }
                } @{$filter->{value}};
            }
            else {
                $filter_text = $filter->{value}->[0];
            }
        }
        else {
            push @queries, "field$filter->{id}=".uri_escape_utf8($_)
                foreach @{$filter->{value}};
        }
    }
    foreach my $key (grep { $_ !~ /^field/ } keys %{$options{query_parameters}})
    {
        push @queries, "$key=$_"
            foreach $options{query_parameters}->get_all($key);
    }
    my $url_filter_remove = join '&', @queries;

    my $record = $options{record};

    my $data = $options{datum_presentation};
    my $display_for_edit;
    if ($options{edit})
    {
        $display_for_edit = $self->userinput;
        # Do not show field if it's an approval request but a value not needing approval
        $display_for_edit = 0
            if $options{approval} && $data && !$data->has_value;
        # Do not show if it's a child record and the value doesn't exist
        $display_for_edit = 0
            if $record->parent_id && !$self->can_child && !$record->layout->user_can("create_child");
        # Do not show if it's a linked record and the value is linked
        $display_for_edit = 0
            if $record->linked_id && $self->link_parent;
    }

    my $return = {
        id                  => $self->id,
        type                => $self->type,
        name                => $self->name,
        description         => $self->description,
        is_id               => $self->name_short && $self->name_short eq '_id',
        topic               => $self->topic,
        topic_id            => $self->topic && $self->topic->id,
        multivalue          => $self->multivalue,
        has_multivalue_plus => $self->has_multivalue_plus,
        helptext            => $self->helptext,
        readonly            => $options{new} ? !$self->user_can('write_new') : !$self->user_can('write_existing'),
        data                => $data,
        is_group            => $options{group} && $options{group} == $self->id,
        has_filter          => $has_filter,
        url_filter_remove   => $url_filter_remove,
        filter_values       => encode_json \@filter_values,
        filter_text         => $filter_text,
        has_filter_search   => 1,
        fixedvals           => $self->fixedvals,
        widthcols           => $self->widthcols,
        optional            => $self->optional,
        userinput           => $self->userinput,
        has_display_field   => $self->has_display_field,
        display_fields_b64  => $self->display_fields_b64,
        display_for_edit    => $display_for_edit,
    };

    if (my $sort = $options{sort})
    {
        if ($sort->{id} == $self->id)
        {
            if ($sort->{type} eq 'asc')
            {
                $return->{sort} = {
                    symbol  => '&udarr;',
                    text    => 'descending', # Text to change the sort
                    current => '&darr;',
                    link    => $self->id.'desc',
                    aria    => 'ascending', # Current sort
                };
            }
            else {
                $return->{sort} = {
                    symbol  => '&udarr;',
                    text    => 'ascending',
                    current => '&uarr;',
                    link    => $self->id.'asc',
                    aria    => 'descending',
                };
            }
        }
        else {
            $return->{sort} = {
                symbol => '&darr;',
                text   => 'ascending',
                link   => $self->id.'asc',
            };
        }
    }

    $self->after_presentation($return, %options);

    return $return;
}

sub after_presentation {}; # Dummy, overridden

1;
