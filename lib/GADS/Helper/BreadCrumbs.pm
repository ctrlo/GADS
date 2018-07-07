package GADS::Helper::BreadCrumbs;

use base qw(Exporter);

our @EXPORT_OK = qw(
    Crumb
);

sub _breadcrumb_home
{   my $instance_name = shift;
    +{
        text => "$instance_name home",
        href => '/',
    }
};

sub Crumb
{   if (@_ == 1)
    {
        my $instance_name = shift;
        return _breadcrumb_home($instance_name) unless @_;
    }

    my ($href, $text) = @_;
    return +{
        text => $text,
        href => $href
    };
}

1;
