package GADS::Role::Presentation::Column;

use Moo::Role;

sub presentation {
    my ($self, %options) = @_;

    my $return = {
        id            => $self->id,
        type          => $self->type,
        name          => $self->name,
        topic         => $self->topic && $self->topic->name,
        is_multivalue => $self->multivalue,
        helptext      => $self->helptext,
        data          => $options{datum_presentation},
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

    return $return;
}

1;
