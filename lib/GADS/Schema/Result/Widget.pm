use utf8;
package GADS::Schema::Result::Widget;

use strict;
use warnings;

__PACKAGE__->mk_group_accessors('simple' => qw/layout current_id/);

use base 'DBIx::Class::Core';

use JSON qw(decode_json);
use Log::Report 'linkspace';
use MIME::Base64 qw/encode_base64/;
use Session::Token;
use Template;

use JSON qw(decode_json encode_json);

__PACKAGE__->load_components("InflateColumn::DateTime", "+GADS::DBIC");

__PACKAGE__->table("widget");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "grid_id",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "dashboard_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "title",
  { data_type => "text", is_nullable => 1 },
  "static",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "h",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "w",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "x",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "y",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "content",
  { data_type => "text", is_nullable => 1 },
  "view_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "graph_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "rows",
  { data_type => "integer", is_nullable => 1 },
  "options",
  { data_type => "text", is_nullable => 1 },
  "tl_options", # Deprecated
  { data_type => "text", is_nullable => 1 },
  "globe_options", # Deprecated
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("widget_ux_dashboard_grid", ["dashboard_id", "grid_id"]);

__PACKAGE__->belongs_to(
  "dashboard",
  "GADS::Schema::Result::Dashboard",
  { id => "dashboard_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "view",
  "GADS::Schema::Result::View",
  { id => "view_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "graph",
  "GADS::Schema::Result::Graph",
  { id => "graph_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

sub options_inflated
{   my $self = shift;
    return {} if !$self->options;
    decode_json $self->options;
}

sub before_create
{   my $self = shift;
    if (!$self->grid_id)
    {
        # Potential race condition, but unlikely and unique constrant will
        # catch anyway
        my $schema = $self->result_source->schema;
        my $grid_id;
        my $existing = $schema->resultset('Widget')->search({
            dashboard_id => $self->dashboard_id,
        });
        while (!$grid_id || $existing->search({ grid_id => $grid_id })->count)
        {
            $grid_id = Session::Token->new( length => 32 )->get;
        }
        $self->grid_id($grid_id);
    }
}

sub is_integer
{   $_[0] =~ /^[0-9]+$/;
}

sub validate
{   my $self = shift;
    $self->type('notice') if !$self->type; # XXX Temp until widget type can be defined
    if ($self->dashboard->is_record)
    {
        $self->type =~ /^(notice|timeline|field|table)$/
            or error __x"Invalid widget type: {type}", type => $self->type;
    }
    else {
        $self->type =~ /^(notice|table|graph|timeline|globe)$/
            or error __x"Invalid widget type: {type}", type => $self->type;
    }
    ! defined $self->h || is_integer($self->h)
        or error __x"Invalid h value {value}", value => $self->h;
    ! defined $self->w || is_integer($self->w)
        or error __x"Invalid w value {value}", value => $self->w;
    ! defined $self->x || is_integer($self->x)
        or error __x"Invalid x value {value}", value => $self->x;
    ! defined $self->y || is_integer($self->y)
        or error __x"Invalid y value {value}", value => $self->y;
    ! defined $self->rows || is_integer($self->rows)
        or error __x"Invalid rows value {value}", value => $self->rows;

    # Validate individual options
    if ($self->type eq 'timeline' && $self->dashboard->is_record)
    {
        my %options = %{$self->options_inflated};
        my $column_ids = delete $options{column_ids} || [];
        ref $column_ids eq 'ARRAY'
            or error "Incorrect value type for columns";
        error "Invalid column ID in columns configuration"
            if grep $_ !~ /^[_0-9]+$/, @$column_ids;
        my $timeline_range = delete $options{timeline_range};
        !$timeline_range || $timeline_range =~ /^(3|6|12|24)$/
            or error __x"Invalid timeline range: {range}", range => $timeline_range;
        error "Unexpected keys in widget configuration"
            if keys %options;
    }
}

sub html
{   my $self = shift;

    my $params = {
        type  => $self->type,
        title => $self->title,
    };

    if ($self->type eq 'notice')
    {
        $params->{content} = $self->content;
    }
    else {
        my $layout = $self->layout
            or panic "Missing layout";

        my $user   = $layout->user;
        my $schema = $self->result_source->schema;

        my $view = GADS::View->new(
            id                       => $self->view_id,
            instance_id              => $layout->instance_id,
            schema                   => $schema,
            layout                   => $self->layout,
        );

        if ($self->type eq 'table' && $self->dashboard->is_record)
        {
            # The field from the record from which the referenced table is
            # being rendered
            my $source_column = $layout->column($self->options_inflated->{column_id});
            if (!$self->view_id || !$self->rows || !$source_column)
            {
                $params->{type} = 'notice';
                $params->{content} = 'Configuration required';
            }
            elsif ($view->current_user_has_access)
            {
                # Need to construct a view which is the one from the
                # destination table selected, but only included the records
                # relevant to the the curcommon of this particular record.
                my $layout_parent = $source_column->layout_parent;
                # First need to find the remote field referring this one:
                my ($remote_field) = $source_column->type eq 'curval'
                    ? grep { $_->type eq 'autocur' && $_->related_field->id == $source_column->id } $layout_parent->all
                    : $source_column->related_field;
                if ($remote_field)
                {
                    my $filter = GADS::Filter->new(
                        as_hash => {
                            rules     => [
                                {
                                    id       => $remote_field->id,
                                    type     => 'string',
                                    value    => $self->current_id,
                                    operator => 'equal',
                                },
                                $view->filter->as_hash,
                            ],
                            operator => 'AND',
                        },
                    );
                    # Temporarily store new filter, but do not write
                    $view->filter($filter);
                    my $records = GADS::Records->new(
                        user   => $user,
                        layout => $layout_parent,
                        schema => $schema,
                        page   => 1,
                        view   => $view,
                        rows   => $self->rows,
                        #rewind => session('rewind'), # Maybe add in the future
                    );
                    my @columns = @{$records->columns_render};
                    $params->{records} = $records->presentation;
                    $params->{layout}  = $layout_parent,
                    $params->{columns} = [ map $_->presentation(sort => $records->sort_first), @columns ];
                }
                else {
                    # Graceful error
                    $params->{type} = 'notice';
                    $params->{content} = 'The table that this value refers to requires an autocur field';
                }
            }
            else {
                # Fail cleanly with useful message. If attempting previous step
                # using a view with no access, then a Log::Report error will be
                # thrown instead.
                $params->{type} = 'notice';
                $params->{content} = 'You do not have access to the configured view for this widget';
            }
        }
        elsif ($self->type eq 'table')
        {
            if (!$self->view_id || !$self->rows)
            {
                $params->{type} = 'notice';
                $params->{content} = 'Configuration required';
            }
            elsif ($view->current_user_has_access)
            {
                my $records = GADS::Records->new(
                    user   => $user,
                    layout => $layout,
                    schema => $schema,
                    page   => 1,
                    view   => $view,
                    rows   => $self->rows,
                    #rewind => session('rewind'), # Maybe add in the future
                );
                my @columns = @{$records->columns_render};
                $params->{records} = $records->presentation;
                $params->{layout}  = $layout,
                $params->{columns} = [ map $_->presentation(sort => $records->sort_first), @columns ];
            }
            else {
                # Fail cleanly with useful message. If attempting previous step
                # using a view with no access, then a Log::Report error will be
                # thrown instead.
                $params->{type} = 'notice';
                $params->{content} = 'You do not have access to the configured view for this widget';
            }
        }
        elsif ($self->type eq 'graph')
        {
            return 'Configuration required' if !$self->view_id || !$self->graph_id;
            my $records = GADS::RecordsGraph->new(
                user                => $user,
                layout              => $layout,
                schema              => $schema,
            );
            my $gdata = GADS::Graph::Data->new(
                id      => $self->graph_id,
                records => $records,
                schema  => $schema,
                view    => $view,
            );
            my $plot_data = encode_base64 $gdata->as_json, ''; # base64 plugin does not like new lines in content $gdata->as_json;
            my $graph = GADS::Graph->new(
                id     => $self->graph_id,
                layout => $layout,
                schema => $schema,
            );
            my $options_in = encode_base64 $graph->as_json, '';

            $params->{graph_id}     = $self->graph_id;
            $params->{plot_data}    = $plot_data;
            $params->{plot_options} = $options_in;
        }
        elsif ($self->type eq 'timeline' && $self->dashboard->is_record)
        {
            my $options = $self->options_inflated;
            my $range   = $options->{timeline_range} || 12;
            my ($lower, $upper)
                = $range == 3 ? (1, 2)
                : $range == 6 ? (1, 5)
                : $range == 12 ? (2, 10)
                : (3, 21); # 24

            # XXX Columns can be normal IDs from the same table, or can be
            # parent/child IDs (with underscore) for curcommons. For the
            # latter, GADS::Records currently does not support retrieval as
            # such, so convert these into the parent only. Thus these dates
            # will only be rendered if the field in question is included as a
            # displayed field in the curcommon field.
            my @column_ids = map {
                $_ =~ /([0-9]+)_/ ? $1 : $_
            } @{$options->{column_ids}};
            my $records = GADS::Records->new(
                current_ids => [$self->current_id],
                columns     => \@column_ids,
                user        => $user,
                layout      => $layout,
                from        => DateTime->now->subtract(months => $lower),
                to          => DateTime->now->add(months => $upper),
                schema      => $schema,
            );
            my $timeline = $records->data_timeline(label_as_field => 1);

            $params->{records}   = encode_base64(encode_json(delete $timeline->{items}), '');
            $params->{dashboard} = 1;
            $params->{timeline}  = $timeline;
        }
        elsif ($self->type eq 'timeline')
        {
            return 'Configuration required' if !$self->view_id;
            my $records = GADS::Records->new(
                user                => $user,
                view                => $view,
                layout              => $layout,
                # No "to" - will take appropriate number from today
                from                => DateTime->now, # Default
                schema              => $schema,
            );
            my $tl_options = $self->options_inflated;
            my $timeline = $records->data_timeline(%{$tl_options});

            $params->{records}   = encode_base64(encode_json(delete $timeline->{items}), '');
            $params->{groups}    = encode_base64(encode_json(delete $timeline->{groups}), '');
            $params->{dashboard} = 1;
            $params->{view_id}   = $view->id;
            $params->{timeline}  = $timeline;
        }
        elsif ($self->type eq 'globe')
        {
            return 'Configuration required' if !$self->view_id;
            my $records_options = {
                user   => $user,
                view   => $view,
                layout => $layout,
                schema => $schema,
            };
            my $globe_options = $self->options_inflated;
            my $globe = GADS::Globe->new(
                group_col_id    => $globe_options->{group},
                color_col_id    => $globe_options->{color},
                label_col_id    => $globe_options->{label},
                records_options => $records_options,
            );
            $params->{globe_data} = encode_base64(encode_json($globe->data), '');
        }
        elsif ($self->type eq 'field')
        {
            my $options = $self->options_inflated;
            my $current_id = $self->current_id
                or error __x"No record ID provided for field widget {id}", id => $self->id;
            my $records = GADS::Records->new(
                current_ids => [$current_id],
                columns     => $options->{column_ids},
                user        => $user,
                layout      => $layout,
                schema      => $schema,
            );
            my $record = $records->single
                or error __x"Record ID {id} not found", id => $self->current_id;
            $params->{record} = $record->presentation;
            $params->{show_field_labels} = $options->{show_field_labels};
        }
    }

    my $config = GADS::Config->instance;
    my $template = Template->new(INCLUDE_PATH => $config->template_location);
    my $output;
    my $t = $template->process('snippets/widget_content.tt', $params, \$output)
        or panic $template->error;
    return $output;
}

1;
