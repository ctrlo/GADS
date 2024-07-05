package GADS::Role::Purgable;

use strict;
use warnings;

use Moo::Role;

has valuefield => (
    is      => 'lazy',
    builder => sub { ('value'); }
);

sub purge {
    my ($self,$user) = @_;
    
    my @field = $self->valuefield or error __"No valuefield defined";
    my $schema = $self->result_source->schema;

    my $purge_needed = grep { $self->$_ } @field;
    if($purge_needed) {
        $schema->txn_do(sub {
            my %fields = { purged_by => $user, purged_on => DateTime->now() };
            $fields{$_} = undef foreach @field;
            $self->update(\%fields);
        });
    }
}

1;