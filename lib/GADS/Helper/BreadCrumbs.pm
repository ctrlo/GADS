package GADS::Helper::BreadCrumbs;

use base qw(Exporter);

our @EXPORT_OK = qw(
    Crumb
);

sub Crumb
{   if (@_ == 1)
    {
        my $layout = shift;
        return +{
            text => $layout->name,
            href => "/".$layout->identifier,
        }
    }

    my $prefix = '';
    if (@_ % 1)
    {
        my $layout = shift;
        $prefix = '/'.$layout->identifier;
    }

    my ($href, $text) = @_;
    return +{
        text => $text,
        href => "$prefix$href",
    };
}

1;
