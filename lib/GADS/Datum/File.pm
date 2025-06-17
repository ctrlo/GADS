=pod
GADS - Globally Accessible Data Store
Copyright (C) 2014 Ctrl O Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

package GADS::Datum::File;

use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;
use namespace::clean;

use MIME::Base64 qw(encode_base64);

extends 'GADS::Datum';

with 'GADS::Role::Presentation::Datum::File';

after set_value => sub {
    my ($self, $value) = @_;
    my $clone = $self->clone; # Copy before changing text

    my @in = sort grep {$_} ref $value eq 'ARRAY' ? @$value : ($value);

    my @values;
    foreach my $val (@in)
    {
        # Files should normally only be submitted by IDs. Allow submission by
        # hashref for tests etc
        if (ref $val eq 'HASH')
        {
            my $file = $self->schema->resultset('Fileval')->create_with_file({
                name     => $val->{name},
                mimetype => $val->{mimetype},
                content  => $val->{content},
            });
            push @values, $file->id;
        }
        else {
            push @values, $val;
        }
    }

    my @old    = sort @{$self->ids};
    my $changed = "@values" ne "@old";

    if ($changed)
    {
        foreach (@values)
        {
            $self->column->validate($_, fatal => 1);
        }
        # Simple test to see if the same file has been uploaded. Only works for
        # single files.
        if (@values == 1 && @old == 1)
        {
            my $old_value   = $self->schema->resultset('Fileval')->find($old[0]); # Only do one fetch here
            my $old_content = $old_value->content;
            my $old_name    = $old_value->name;
            if(my $fl = $self->schema->resultset('Fileval')->search({
                id      => $values[0],
                name    => $old_name
            })->next) {
                $changed = 0 if $fl && $fl->content == $old_content;
            }
        }
    }
    if ($changed)
    {
        $self->clear_files;
        $self->clear_init_value;
    }
    $self->changed($changed);
    $self->oldvalue($clone);
    $self->has_ids(1);
    $self->ids(\@values);
};

has ids => (
    is      => 'rw',
    lazy    => 1,
    coerce  => sub { ref $_[0] eq 'ARRAY' ? $_[0] : [$_[0]] },
    trigger => sub {
        my $self = shift;
        $self->clear_blank;
    },
    builder => sub {
        my $self = shift;
        [ map { $_->{id} } @{$self->files} ];
    },
);

sub _build_blank { @{$_[0]->ids} ? 0 : 1 }

has has_ids => (
    is  => 'rw',
    isa => Bool,
);

sub value {
    my $self = shift;
    if ($self->column->multivalue) {
        return [ map { $_->{name} } @{$self->files} ];
    }
    else {
        $self->as_string || undef;
    }
}

has value_hash => (
    is      => 'rw',
    lazy    => 1,
);

# Make up for missing predicated value property
sub has_value { $_[0]->has_ids }

has files => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

sub _build_files
{   my $self = shift;

    return [+{
        id => -1,
        name => 'Purged',
        mimetype => 'text/plain',
    }] if $self->is_purged;

    my @return;

    if ($self->has_init_value)
    {
        # XXX - messy to account for different initial values. Can be tidied once
        # we are no longer pre-fetching multiple records
        my @init_value = $self->has_init_value ? @{$self->init_value} : ();
        my @values     = map { ref $_ eq 'HASH' && exists $_->{record_id} ? $_->{value} : $_ } @init_value;

        @return = map {
            ref $_ eq 'HASH'
            ? +{
                id       => $_->{id},
                name     => $_->{name},
                mimetype => $_->{mimetype},
            } : $self->_ids_to_files($_)
        } grep { ref $_ eq 'HASH' ? $_->{id} : $_ } @values;
        $self->has_ids(1) if @values || $self->init_no_value;
    }
    elsif ($self->has_ids) {
        @return = $self->_ids_to_files(@{$self->ids});
    }

    return \@return;
}

sub _files_rs
{   my $self = shift;
    [$self->schema->resultset('File')->search({
        record_id => $self->record_id,
        layout_id => $self->column->id,
    })->all];
}

sub is_purged {
    my $self = shift;
    my @files = @{$self->_files_rs};
    return grep { $_->is_purged } @files;
}

sub _ids_to_files
{   my ($self, @ids) = @_;
    map {
        +{
            id       => $_->id,
            name     => $_->name,
            mimetype => $_->mimetype,
        };
    } $self->schema->resultset('Fileval')->search({
        id => \@ids,
    },{
        columns => [qw/id name mimetype/],
    })->all;
}

sub search_values_unique
{   my $self = shift;
    [ map { $_->{name} } @{$self->files} ]
}

# Needed in case this is unattached file, in which case schema
# is not in column property
has schema => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->column->schema;
    },
);

has _rset => (
    is => 'lazy',
);

sub _build__rset
{   my $self = shift;
    my $ids = $self->ids or return;
    @$ids or return;
    @$ids > 1
        and error "Only one file can be returned, and this value contains more than one file";
    my $id = shift @$ids;
    $self->column->user_can('read') or error __x"You do not have access to file ID {id}", id => $id
        if $self->column;
    $self->schema->resultset('Fileval')->find($id);
}

has single_name => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->_rset && $_[0]->_rset->name;
    },
);

has single_mimetype => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->_rset && $_[0]->_rset->mimetype;
    },
);

has single_content => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->_rset && $_[0]->_rset->content;
    },
);

has single_id => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->_rset && $_[0]->_rset->id;
    },
);

has single_rset => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        $_[0]->_rset;
    },
);

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self,
        ids   => $self->ids,
        files => $self->files,
        @_,
    );
};

sub for_table
{   my $self = shift;
    my $return = $self->for_table_template;
    $return->{values} = $self->files;
    $return;
}

sub as_string
{   my $self = shift;
    my @files = @{$self->files}
        or return '';
    return join ', ', map { $_->{name} } @files;
}

sub as_integer
{   my $self = shift;
    panic "Not implemented";
}

sub html_form
{   my $self = shift;
    return $self->ids;
}

sub _build_for_code
{   my $self = shift;
    my @return = map { $_->{name} } @{$self->files};
    # Make consistent with JS
    $self->column->multivalue ? \@return : $return[0];
}

1;

