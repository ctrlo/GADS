package GADS::Role::Presentation::Column::Tree;

use Moo::Role;

sub after_presentation
{   my ($self, $return) = @_;

    $return->{end_node_only} = $self->end_node_only;
}

1;
