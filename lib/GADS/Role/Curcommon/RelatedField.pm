package GADS::Role::Curcommon::RelatedField;

use Moo::Role;
use MooX::Types::MooseLike::Base qw/:all/;

has related_field => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;

        # Under normal circumstances we will have a full layout with columns
        # built. If not, fall back to retrieving from database. The latter is
        # needed when initialising the schema in GADS::DB::setup()
        $self->layout->column($self->related_field_id)
            || $self->schema->resultset('Layout')
            ->find($self->related_field_id);
    },
);

has related_field_id => (
    is      => 'rw',
    isa     => Maybe [Int],  # undef when importing and ID not known at creation
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_rset && $self->_rset->get_column('related_field');
    },
    trigger => sub {
        my ($self, $value) = @_;
        $self->clear_related_field;
    },
);

sub _build_related_field_id
{   my $self = shift;
    $self->related_field->id;
}

1;
