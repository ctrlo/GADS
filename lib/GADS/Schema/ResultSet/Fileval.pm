package GADS::Schema::ResultSet::Fileval;

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

use Log::Report 'linkspace';

use GADS::Datum::File;
use GADS::Layout;

sub independent
{   shift->search_rs({
        is_independent => 1,
    },{
        order_by => 'me.id',
    });
}

sub find_with_permission
{   my ($self, $id, $user) = @_;

    my $fileval = $self->find($id) or return;

    my $file = GADS::Datum::File->new(ids => $id);

    # Attached to a record value?
    my ($file_rs) = $fileval->files; # In theory can be more than one, but not in practice (yet)

    # Get appropriate column, if applicable (could be unattached document)
    # This will control access to the file
    if ($file_rs && $file_rs->layout_id)
    {
        my $layout = GADS::Layout->new(
            user        => $user,
            schema      => $self->result_source->schema,
            instance_id => $file_rs->layout->instance_id,
        );
        # GADS::Datum::File will check for access to this field
        $file->column($layout->column($file_rs->layout_id));
        $file->single_content;
    }
    elsif (!$fileval->is_independent)
    {
        # If the file has been uploaded via a record edit and it hasn't been
        # attached to a record yet (or the record edit was cancelled) then do
        # not allow access
        error __"Access to this file is not allowed"
            unless $fileval->edit_user_id && $fileval->edit_user_id == $user->id;
        $file->schema($self->result_source->schema);
    }
    else {
        $file->schema($self->result_source->schema);
    }

    $file;
}

1;
