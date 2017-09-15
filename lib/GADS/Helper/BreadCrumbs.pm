package GADS::Helper::BreadCrumbs;

use base qw(Exporter);

our @EXPORT_OK = qw(
    Crumb
);

sub BreadCrumbHome {
    +{
        text => 'Linkspace home', # FIXME System name instead
        href => '/',
    }
};

sub Crumb {
    return BreadCrumbHome() unless @_;

    my ($href, $text) = @_;
    return +{
        text => $text,
        href => $href
    };
}

1;
