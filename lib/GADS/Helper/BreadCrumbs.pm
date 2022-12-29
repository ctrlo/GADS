package GADS::Helper::BreadCrumbs;

use base qw(Exporter);

our @EXPORT_OK = qw(
    Crumb
);

sub Crumb
{
    my ($href, $text) = @_;

    return +{
        text => $text,
        href => $href,
        is_link => $href ? 1 : 0,
    };
}

1;
