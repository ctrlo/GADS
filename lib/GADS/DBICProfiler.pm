package GADS::DBICProfiler;
use strict;

use Log::Report;

use base 'DBIx::Class::Storage::Statistics';
 
use Time::HiRes qw(time);
 
my $start;
 
sub query_start {
  my $self = shift();
  my $sql = shift();
  my @params = @_;
 
  trace "Executing SQL: $sql: ".join(', ', @params);
  $start = time();
}
 
sub query_end {
  my $self = shift();
  my $sql = shift();
  my @params = @_;
 
  my $elapsed = sprintf("%0.4f", time() - $start);
  trace "Execution took $elapsed seconds.";
  $start = undef;
}
 
1;

