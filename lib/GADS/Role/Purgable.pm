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

sub is_purged {
    my $self = shift;
    return $self->purged_on && $self->purged_by ? 1 : 0;
}

sub purge {
    my ($self,$user) = @_;

    my @fields = @{$self->value_fields} or panic __"No valuefield defined";
    my $schema = $self->result_source->schema;

    my $guard = $schema->txn_scope_guard;

    if(!$self->is_purged) {
        $self->update({ purged_by => $user, purged_on => DateTime->now() });
        $self->update({$_ => undef}) foreach @fields;
    }

    $guard->commit;
}

1;