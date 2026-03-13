#!/usr/bin/perl

use strict;
use warnings;

use feature 'say';

use FindBin qw($Bin);

use lib "$Bin/../lib";

use JSON qw(from_json);

use GADS::Instances;
use GADS::Config;

use Getopt::Long;

use Dancer2 appname => 'Linkspace';
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport;

my ( $view_id, $view_name, $verbose );

GetOptions(
    'view_id=i'   => \$view_id,
    'view_name=s' => \$view_name,
    'verbose'     => \$verbose,
);

# We only want one of view_id or view_name, not both or neither
error "Usage $0 (--view_id=<id>|--view_name=<name>)"
  if ( !$view_id && !$view_name ) || ( $view_id && $view_name );

GADS::Config->instance( config => config );

schema->storage->debug(1) if $verbose;

my $rset_view;
if ($view_name) {
    $rset_view = schema->resultset('View')->find( { name => $view_name } );
}
else {
    $rset_view = schema->resultset('View')->find($view_id);
}

error __x"Unable to find view with {view}", view => ( $view_id ? "id $view_id" : "name $view_name" )
  unless $rset_view;

my $user = schema->resultset('User')->find( { id => $rset_view->user_id } )
  or die "User not found";

my $instance = [
    grep { $_->instance_id == $rset_view->instance_id }
      @{ GADS::Instances->new(
            user   => $user,
            schema => schema,
        )->all
      }
]->[0];

my $filter = from_json( $rset_view->filter );

my $view = GADS::View->new(
    user        => $user,
    schema      => schema,
    instance_id => $instance->instance_id,
    layout      => $instance,
    filter      => $filter,
);

my $records = GADS::Records->new(
    user           => $user,
    schema         => schema,
    no_view_limits => 1,
    layout         => $instance,
    view           => $view,
);

my $txn = schema->txn_scope_guard;

unlink 'rollback.log' if -e 'rollback.log';

open my $log, '>', 'rollback.log' or die "Could not open log file: $!";

print $log localtime() . " STARTING ROLLBACK\n";
for ( map { schema->resultset('Record')->find( $_->record_id ) } @{ $records->results } )
{
    my $id         = $_->id;
    my $current_id = $_->current_id;
    my $created    = $_->created;
    my $createdby  = $_->createdby->email;
    print $log "Record ID $id (current id: $current_id) created at $created by $createdby\n";
    info "Record ID $id (current id: $current_id) created at $created by $createdby";
    $_->calcvals->delete;
    $_->curvals->delete;
    $_->dateranges->delete;
    $_->dates->delete;
    $_->enums->delete;
    $_->files->delete;
    $_->intgrs->delete;
    $_->people->delete;
    $_->ragvals->delete;
    $_->strings->delete;
    $_->user_lastrecords->delete;
    my $current = schema->resultset('Current')->find( { current_version_id => $_->id } )
      or die "Current not found for record id $id";
    $current->update( { current_version_id => undef } );
    $_->delete;
    my $replacement = schema->resultset('Record')->search(
        {
            current_id => $current->id
        },
        {
            rows     => 1,
            order_by => { -desc => 'created' },
        }
    )->next;
    $current->update( { current_version_id => $replacement->id } );
}
$txn->commit;
print $log localtime() . " ENDING ROLLBACK\n";
info scalar( @{ $records->results } ) . " results";

close $log;

exit 0;
