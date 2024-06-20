#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport 'linkspace';
use GADS::DB;
use GADS::Layout;
use GADS::Column::Calc;
use GADS::Column::Curval;
use GADS::Column::Date;
use GADS::Column::Daterange;
use GADS::Column::Enum;
use GADS::Column::File;
use GADS::Column::Intgr;
use GADS::Column::Person;
use GADS::Column::Rag;
use GADS::Column::String;
use GADS::Column::Tree;
use GADS::Config;
use GADS::Instances;
use GADS::Graph;
use GADS::Graphs;
use GADS::Groups;
use GADS::MetricGroups;
use GADS::Schema;
use Getopt::Long;
use JSON qw();
use Log::Report syntax => 'LONG';
use String::CamelCase qw(camelize);

my ($new_format);

GetOptions('to=s' => \$new_format,)
    or exit;

$new_format or report ERROR => "Please provide new date format with --to";

my $config = GADS::Config->instance(config => config,);

use GADS::DateTime;

foreach my $site (schema->resultset('Site')->all)
{
    schema->site_id($site->id);
    my $instances = GADS::Instances->new(
        schema                   => schema,
        user                     => undef,
        user_permission_override => 1,
    );

    foreach my $layout (@{ $instances->all })
    {
        my $views = GADS::Views->new(
            layout                   => $layout,
            instance_id              => $layout->instance_id,
            schema                   => schema,
            user_permission_override => 1,
        );
        foreach my $view (@{ $views->all })
        {
            foreach my $filter (@{ $view->filter->filters })
            {
                my $column = $layout->column($filter->{column_id});
                $column
                    or error __x
                    "Invalid column_id {col_id} for view {view_id}",
                    col_id  => $filter->{column_id},
                    view_id => $view->id;
                next
                    unless $column->return_type eq 'date'
                    || $column->return_type eq 'daterange';
                error "Unable to process daterange columns"    # Todo
                    if $column->return_type eq 'daterange';
                my @vals =
                    ref $filter->{value} eq 'ARRAY'
                    ? @{ $filter->{value} }
                    : $filter->{value};
                next if !@vals;
                @vals == 1 or error "Unexpected number of values for filter";
                my $value = GADS::DateTime::parse_datetime(@vals)
                    or next;
                $filter->{value} = $value->format_cldr($new_format);
            }
            $view->filter->clear_as_json;
            $view->write(no_errors => 1);
        }
    }
}
