package GADS::Routes::Report;

use Dancer2 appname => 'GADS';
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::DBIC;

use List::MoreUtils qw(uniq);

prefix '/report' => sub {

    #view all reports for this instance
    get '' => require_login sub {
        my $user   = logged_in_user;
        my $layout = var('layout') or pass;

        if ( app->has_hook('plugin.linkspace.data_before_request') ) {
            app->execute_hook( 'plugin.linkspace.data_before_request',
                user => $user );
        }

        my %params = (
            user   => $user,
            layout => $layout,
            schema => schema,
        );

        my $records = GADS::Records->new(%params);

        my $alert = GADS::Alert->new(
            user   => $user,
            layout => $layout,
            schema => schema,
        );

        my $base_url = request->base;

        my $params;

        $params->{alerts}      = $alert->all;
        $params->{header_type} = 'table_tabs';

        $params->{layout_obj} = $layout;
        $params->{layout}     = $layout;

        $params->{header_back_url} = "${base_url}table";
        $params->{breadcrumbs}     = [
            Crumb( $base_url . "table/", "Tables" ),
            Crumb( "",                   "Table: " . $layout->name )
        ];

        my $layout_id = $layout->{instance_id};

        my $reports = schema->resultset('Report')->load_all_reports($layout_id);

        $params->{viewtype} = 'table';
        $params->{reports}  = $reports;

        template 'report' => $params;
    };

    #add a report
    any [ 'get', 'post' ] => '/add' => require_login sub {
        if ( body_parameters && body_parameters->{submit} ) {
            my $layout               = var('layout') or pass;
            my $report_description   = body_parameters->{report_description};
            my $report_name          = body_parameters->{report_name};
            my $checkbox_fields_full = body_parameters->{checkbox_fields};
            my $instance             = $layout->{instance_id}
              if $layout && $layout->{instance_id};

            error "NO INSTANCE" if !$instance;

            my $checkbox_fields = [ uniq split( ',', $checkbox_fields_full ) ];

            my $user = logged_in_user;

            my $report = schema->resultset('Report')->create(
                {
                    user        => $user,
                    name        => $report_name,
                    description => $report_description,
                    instance_id => $instance,
                    createdby   => $user,
                    layouts     => $checkbox_fields
                }
            );

            my $lo = param 'layout_name';
            return forwardHome( { success => "Report created" }, "$lo/report" );
        }

        my $user   = logged_in_user;
        my $layout = var('layout') or pass;

        if ( app->has_hook('plugin.linkspace.data_before_request') ) {
            app->execute_hook( 'plugin.linkspace.data_before_request',
                user => $user );
        }

        my %params = (
            user   => $user,
            layout => $layout,
            schema => schema,
        );

        my @columns = @{ $layout->all( { user_can_read => 1 } ) };

        my $alert = GADS::Alert->new(
            user   => $user,
            layout => $layout,
            schema => schema,
        );

        my $base_url = request->base;

        my $params;

        $params->{alerts}      = $alert->all;
        $params->{header_type} = 'table_tabs';

        $params->{layout_obj} = $layout;
        $params->{layout}     = $layout;

        $params->{header_back_url} = "${base_url}table";
        $params->{breadcrumbs}     = [
            Crumb( $base_url . "table/", "Tables" ),
            Crumb( "",                   "Table: " . $layout->name )
        ];

        $params->{viewtype} = 'add';
        $params->{fields}   = \@columns;

        template 'report' => $params;
    };

    #Edit a report (by :id)
    any [ 'get', 'post' ] => '/edit:id' => require_login sub {

        if ( body_parameters && body_parameters->{submit} ) {
            my $layout               = var('layout') or pass;
            my $report_description   = body_parameters->{report_description};
            my $report_name          = body_parameters->{report_name};
            my $checkbox_fields_full = body_parameters->{checkbox_fields};
            my $instance             = $layout->{instance_id}
              if $layout && $layout->{instance_id};

            error "NO INSTANCE" if !$instance;

            my $checkbox_fields = [ split( ',', $checkbox_fields_full ) ];

            my $user = logged_in_user;

            my $report_id = param('id');

            my $result =
              schema->resultset('Report')->load_for_edit( $report_id, schema );

            $result->update_report(
                {
                    name        => $report_name,
                    description => $report_description,
                    layouts     => [ uniq grep { $_ ne '' } @$checkbox_fields ]
                }
            );

            my $lo = param 'layout_name';
            return forwardHome( { success => "Report updated" }, "$lo/report" );
        }

        my $user   = logged_in_user;
        my $layout = var('layout') or pass;

        if ( app->has_hook('plugin.linkspace.data_before_request') ) {
            app->execute_hook( 'plugin.linkspace.data_before_request',
                user => $user );
        }

        my %params = (
            user   => $user,
            layout => $layout,
            schema => schema,
        );

        my @columns = @{ $layout->all( { user_can_read => 1 } ) };

        my $alert = GADS::Alert->new(
            user   => $user,
            layout => $layout,
            schema => schema,
        );

        my $base_url = request->base;

        my $params;

        $params->{alerts}      = $alert->all;
        $params->{header_type} = 'table_tabs';

        $params->{layout_obj} = $layout;
        $params->{layout}     = $layout;

        $params->{header_back_url} = "${base_url}table";
        $params->{breadcrumbs}     = [
            Crumb( $base_url . "table/", "Tables" ),
            Crumb( "",                   "Table: " . $layout->name )
        ];

        my $report_id = param('id');

        my $result = schema->resultset('Record')->load_for_edit($report_id);

        my $report_layouts = $result->report_layouts;

        my $layouts = [];

        while ( my $report_layout = $report_layouts->next ) {
            push @$layouts, $report_layout->layout_id;
        }

        foreach my $field (@columns) {
            if ( grep { $_ eq $field->{id} } @$layouts ) {
                $field->{is_checked} = 1;
            }
        }

        $params->{report}   = $result;
        $params->{fields}   = \@columns;
        $params->{viewtype} = 'edit';

        template 'report' => $params;
    };

    #Delete a report (by :id)
    get "/delete:id" => sub {
        my $user   = logged_in_user;
        my $layout = var('layout') or pass;

        my $report_id = param('id');

        my $result = schema->resultset('Report')->load_for_edit($report_id);

        $result->delete;

        my $lo = param 'layout_name';
        return forwardHome( { success => "Report deleted" }, "$lo/report" );
    };

    #Render the report (by :report) with the view (by :view)
    get "/render:report/:view" => sub {
        my $user = logged_in_user;

        my $report_id = param('report');
        my $view_id   = param('view');

        my $report =
          schema->resultset('Report')->load( $report_id, $view_id, schema );

        my $pdf = $report->create_pdf->content;

        return send_file( \$pdf, content_type => 'application/pdf', );
    };
}

1;
