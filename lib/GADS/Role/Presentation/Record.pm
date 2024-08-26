package GADS::Role::Presentation::Record;

use Moo::Role;

with 'GADS::DateTime';

sub edit_columns
{   my ($self, %options) = @_;

    my %permissions = $options{approval} && $options{new}
        ? (user_can_approve_new => 1)
        : $options{approval}
        ? (user_can_approve_existing => 1)
        : $options{new}
        ? (user_can_readwrite_new => 1)
        : (user_can_readwrite_existing => 1);

    my @columns = $self->layout->all(sort_by_topics => 1, can_child => $options{child}, %permissions, exclude_internal => 1);

    @columns = grep $_->userinput || $_->has_browser_code, @columns
        if $options{new};

    @columns = grep !$_->is_curcommon || !$_->show_add , @columns
        if $options{modal};

    @columns = grep $_->type ne 'file', @columns
        if $options{bulk} && $options{bulk} eq 'update';

    return @columns;
}

sub presentation {
    my ($self, %options) = @_;

    # For an edit show all relevant fields for edit, otherwise assume record
    # read and show all view columns
    my @columns = $options{edit}
        ? $self->edit_columns(%options)
        : $options{curval_fields}
        ? @{$options{curval_fields}}
        : $options{group}
        ? @{$self->columns_render}
        : $options{purge}
        ? $self->layout->column_id
        : @{$self->columns_render};

    $options{record} = $self;

    # Work out the indentation each field should have. A field will be indented
    # if it has a display condition of an immediately-previous field. This will
    # be recursive as long as there are additional display-dependent fields.
    my $indent = {}; my $this_indent = {}; my $previous;
    foreach my $col (@columns)
    {
        if ($col->has_display_field)
        {
            foreach my $display_field_id (@{$col->display_field_col_ids})
            {
                my ($seen) = grep { $_ == $display_field_id } keys %$this_indent;
                if ($seen || ($previous && $display_field_id == $previous->id))
                {
                    $indent->{$col->id} = $seen && $indent->{$seen} ? ($indent->{$seen} + 1) : 1;
                    $this_indent->{$col->id} = $indent->{$col->id};
                    last;
                }
                $indent->{$col->id} = 0;
                $this_indent = {
                    $col->id => 0,
                };
            }
        }
        else {
            $indent->{$col->id} = 0;
            $this_indent = {
                $col->id => 0,
            };
        }
        $previous = $col;
    }

    my @presentation_columns = $self->presentation_map_columns(%options, columns => \@columns);
    my @topics= $self->get_topics(\@presentation_columns);

    my $version_datetime_col = $self->layout->column_by_name_short('_version_datetime');
    my $created_user_col     = $self->layout->column_by_name_short('_created_user');
    my $created_datetime_col = $self->layout->column_by_name_short('_created');
    my $return = {
        parent_id       => $self->parent_id,
        linked_id       => $self->linked_id,
        current_id      => $self->current_id,
        record_id       => $self->record_id,
        instance_id     => $self->layout->instance_id,
        columns         => \@presentation_columns,
        topics          => \@topics,
        indent          => $indent,
        deleted         => $self->deleted,
        deletedby       => $self->deletedby,
        user_can_delete => $self->user_can_delete,
        user_can_edit   => $self->layout->user_can('write_existing') || $self->layout->user_can('write_new'),
        id_count        => $self->id_count,
        has_rag_column  => !!(grep { $_->type eq 'rag' } @columns),
        new_entry       => $self->new_entry,
        is_draft        => $self->is_draft,
    };

    if ($options{edit})
    {
        # Building versions is expensive, and not needed when this record is part
        # of a curval value. It's only shown for the edit page
        my $config = GADS::Config->instance;
        my $format = $config->dateformat." HH:mm:ss";
        $return->{versions} = [
            map {
                my $created = $_->created;
                # See timezone comments in GADS::Datum::Date
                $created->time_zone->is_floating && $created->set_time_zone('UTC');
                +{
                    id        => $_->id,
                    created   => $self->date_as_string($created, $format),
                    createdby => $_->createdby,
                }
            } $self->versions
        ]
    }

    if (!$self->new_entry && $options{edit}) # Expensive, only do if necessary
    {
        $return->{version_user} = $self->layout->column_by_name_short('_version_user')->presentation(
            datum_presentation => $self->edited_user->presentation, %options
        );
        $return->{version_datetime} = $version_datetime_col->presentation(
            datum_presentation => $self->edited_time->presentation, %options
        );
        $return->{created_user} = $created_user_col->presentation(
            datum_presentation => $self->created_user->presentation, %options
        );
        $return->{created_datetime} = $created_datetime_col->presentation(
            datum_presentation => $self->created_time->presentation, %options
        );
    }

    return $return;
}

1;
