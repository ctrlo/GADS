package GADS::Role::Purgable;

use strict;
use warnings;

use MooX::Types::MooseLike::Base qw(ArrayRef);

use Moo::Role;

has value_fields => (
    is      => 'lazy',
    isa     => ArrayRef,
    builder => sub { ['value']; }
);

sub purge {
    my ($self,$user) = @_;
    
    my @field = @{$self->value_fields} or panic __"No valuefield defined";
    my $schema = $self->result_source->schema;

    my $purge_needed = grep { $self->$_ } @field;
    $purge_needed = 1 if ref($self) eq "Gads::Schema::Result::File";
    $schema->txn_do(sub {
        $self->update({ purged_by => $user, purged_on => DateTime->now() });
        $self->update({$_ => undef}) foreach @field;
    }) if $purge_needed;
}

1;