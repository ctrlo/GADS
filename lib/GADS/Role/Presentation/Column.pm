package GADS::Role::Presentation::Column;

use Moo::Role;
use JSON        qw(encode_json);
use URI::Escape qw/uri_escape_utf8/;

sub presentation
{   my ($self, %options) = @_;

# data-values='[{"id": "23", "value": "Foo", "checked": true}, {"id": "24", "value": "Bar", "checked": true}]'

    my $record = $options{record};

    my $data = $options{datum_presentation};
    my $display_for_edit;
    if ($options{edit})
    {
        $display_for_edit = $self->userinput || $self->has_browser_code;

# Do not show field if it's an approval request but a value not needing approval
        $display_for_edit = 0
            if $options{approval} && $data && !$data->{has_value};

        # Do not show if it's a child record and the value doesn't exist
        $display_for_edit = 0
            if $record->parent_id
            && !$self->can_child
            && !$record->layout->user_can("create_child");

        # Do not show if it's a linked record and the value is linked
        $display_for_edit = 0
            if $record->linked_id && $self->link_parent;
    }

    my $return = {
        id                  => $self->id,
        type                => $self->type,
        name                => $self->name,
        name_short          => $self->name_short,
        description         => $self->description,
        is_id               => $self->name_short && $self->name_short eq '_id',
        topic               => $self->topic,
        topic_id            => $self->topic && $self->topic->id,
        multivalue          => $self->multivalue,
        has_multivalue_plus => $self->has_multivalue_plus,
        helptext            => $self->helptext,
        helptext_html       => $self->helptext_html,
        readonly            => $options{new}
        ? !$self->user_can('write_new')
        : !$self->user_can('write_existing'),
        data               => $data,
        fixedvals          => $self->fixedvals,
        widthcols          => $self->widthcols,
        optional           => $self->optional,
        userinput          => $self->userinput,
        lookup_endpoint    => $self->lookup_endpoint,
        lookup_fields      => $self->lookup_fields,
        lookup_fields_json => encode_json($self->lookup_fields),
        has_display_field  => $self->has_display_field,
        display_fields_b64 => $self->display_fields_b64,
        display_for_edit   => $display_for_edit,
        depends_on_b64     => $self->depends_on_b64,
        code_b64      => $self->has_browser_code ? $self->code_b64   : undef,
        params_b64    => $self->has_browser_code ? $self->params_b64 : undef,
        addable       => $self->addable,
        return_type   => $self->return_type,
        show_in_edit  => $self->show_in_edit,
        has_typeahead => $self->has_filter_typeahead,
    };

    if (my $sort = $options{sort})
    {
        if ($sort->{id} == $self->id)
        {
            if ($sort->{type} eq 'asc')
            {
                $return->{sort} = {
                    symbol  => '&udarr;',
                    type    => $sort->{type},
                    text    => 'descending',         # Text to change the sort
                    current => '&darr;',
                    link    => $self->id . 'desc',
                    aria    => 'ascending',          # Current sort
                };
            }
            else
            {
                $return->{sort} = {
                    symbol  => '&udarr;',
                    type    => $sort->{type},
                    text    => 'ascending',
                    current => '&uarr;',
                    link    => $self->id . 'asc',
                    aria    => 'descending',
                };
            }
        }
        else
        {
            $return->{sort} = {
                symbol => '&darr;',
                type   => 'none',
                text   => 'ascending',
                link   => $self->id . 'asc',
            };
        }
    }

    $self->after_presentation($return, %options);

    return $return;
}

sub after_presentation { };    # Dummy, overridden

1;
