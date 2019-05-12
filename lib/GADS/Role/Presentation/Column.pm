package GADS::Role::Presentation::Column;

use Moo::Role;

sub presentation {
    my ($self, %options) = @_;

    my $return = {
        id            => $self->id,
        type          => $self->type,
        name          => $self->name,
        is_id         => $self->name_short eq '_id',
        topic         => $self->topic && $self->topic->name,
        topic_id      => $self->topic && $self->topic->id,
        is_multivalue => $self->multivalue,
        helptext      => $self->helptext,
        readonly      => $options{new} ? !$self->user_can('write_new') : !$self->user_can('write_existing'),
        data          => $options{datum_presentation},
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
