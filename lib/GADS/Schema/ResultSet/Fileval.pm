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
{   my ($self, $id, $user, %options) = @_;

    # Checks for whether the file is new or not, and therefore whether access is allowed
    my $new_file_only = delete $options{new_file_only};
    my $rename_existing = delete $options{rename_existing};

    my $fileval = $self->find($id) or return;

    my $file = GADS::Datum::File->new(ids => $id);

    # Attached to a record value?
    my ($file_rs) = $fileval->files; # In theory can be more than one, but not in practice (yet)

    # Get appropriate column, if applicable (could be unattached document)
    # This will control access to the file
    if ($file_rs && $file_rs->layout_id)
    {
        error __"Access to this file is not allowed as it is not a new file"
            if $new_file_only;
        
        my $layout = GADS::Layout->new(
            user        => $user,
            schema      => $self->result_source->schema,
            instance_id => $file_rs->layout->instance_id,
        );
        # GADS::Datum::File will check for access to this field
        $file->column($layout->column($file_rs->layout_id));
        # Need to call this now to check for access to column. layout() is a
        # weak accessor in GADS::Column so will have gone out of scope if
        # called later
        $file->single_content;
        # Also check that user has access to the actual record
        my $record = GADS::Record->new(
            user    => $user,
            schema  => $self->result_source->schema,
            layout  => $layout,
            columns => [],
        );
        # Will error if no access
        $record->find_current_id($file_rs->record->current_id);
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
        error __"Access to this file is not allowed"
            if $new_file_only || $rename_existing;
        $file->schema($self->result_source->schema);
    }

    $file;
}

sub create_with_file {
    my ($self, $name, $mimetype, $content, $independent, $user) = @_;
    
    my $guard = $self->result_source->schema->txn_scope_guard;

    my $return = $self->create({
        name           => $name,
        mimetype       => $mimetype,
        is_independent => $independent || 0,
        edit_user_id   => $user,
    });

    $return->create_file($content);

    $guard->commit;

    $return;
}

1;
