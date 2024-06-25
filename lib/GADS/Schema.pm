use utf8;
package GADS::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

our $VERSION = 107;

our $IGNORE_PERMISSIONS;
our $IGNORE_PERMISSIONS_SEARCH;

__PACKAGE__->mk_group_accessors('simple' => qw/site_id/);

# Resultset to restrict by site ID, if configured
sub resultset
{   my $self = shift;
    my $rs = $self->next::method(@_);
    return $rs if !$self->site_id; # Not set yet
    # Is this the site table itself?
    return $rs->search_rs({ 'me.id' => $self->site_id })
        if $rs->result_source->name eq 'site';
    # Otherwise add a site_id search if applicable
    return $rs unless $rs->result_source->has_column('site_id');
    $rs->search_rs({ 'me.site_id' => $self->site_id });
}

1;
