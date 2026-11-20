package GADS::Helper::Pager;

use strict;
use warnings;

use Exporter qw/import/;

our @EXPORT_OK = qw(get_chronology_page);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub get_chronology_page {
    # This is for Chronology paging - but I felt it may be useful elsewhere too.
    my ($page, $max, @items) = @_;

    my $start = -(($page * $max) + 1);
    my $end = -((($page - 1) * $max) + 1);
    my @result = @items[ $start..$end ];
    return grep { defined } @result;
}

1;

__END__

=encoding utf8

=head1 NAME

GADS::Helper::Pager GADS pager helper.

=head1 SYNOPSIS

    use GADS::Helper::Pager qw(get_chronology_page);

    my @items = get_chronology_page(1, 10, @all_items);

=head1 DESCRIPTION

Helper for paging through items. Currently only used for chronology.

=head1 METHODS

=head2 get_chronology_page

    get_chronology_page($page, $max, @all_items);

Return items for a chronology page.
Takes page number, max per page, and items.

=cut
