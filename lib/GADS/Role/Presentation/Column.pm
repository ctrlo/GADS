package GADS::Role::Presentation::Column;

use Moo::Role;
use JSON qw(encode_json);
use URI::Escape qw/uri_escape_utf8/;

sub presentation {
    my ($self, %options) = @_;

    # data-values='[{"id": "23", "value": "Foo", "checked": true}, {"id": "24", "value": "Bar", "checked": true}]'

    my ($has_filter, @queries, $filter_values);
    foreach my $filter (@{$options{filters}})
    {
        if ($filter->{id} == $self->id)
        {
            $has_filter = 1;
            if ($self->fixedvals)
            {
                my @filter_values = map {
                    +{
                        id      => $_,
                        value   => $self->id_as_string($_),
                        checked => \1,
                    }
                } @{$filter->{value}};
                $filter_values = encode_json \@filter_values;
            }
        }
        else {
            push @queries, "field$filter->{id}=".uri_escape_utf8($_)
                foreach @{$filter->{value}};
        }
    }
    my $url_filter_remove = join '&', @queries;

    my $return = {
        id                  => $self->id,
        type                => $self->type,
        name                => $self->name,
        is_id               => $self->name_short eq '_id',
        topic               => $self->topic && $self->topic->name,
        topic_id            => $self->topic && $self->topic->id,
        is_multivalue       => $self->multivalue,
        helptext            => $self->helptext,
        readonly            => $options{new} ? !$self->user_can('write_new') : !$self->user_can('write_existing'),
        data                => $options{datum_presentation},
        is_group            => $options{group} && $options{group} == $self->id,
        has_filter          => $has_filter,
        url_filter_remove   => $url_filter_remove,
        filter_values       => $filter_values,
        fixedvals           => $self->fixedvals,
    };

    # XXX Reference to self when this is used within edit.tt. Ideally this
    # wouldn't be needed and all parameters that are needed would be passed as
    # above.
    $return->{column} = $self
        if $options{edit};

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

    return $return;
}

1;
