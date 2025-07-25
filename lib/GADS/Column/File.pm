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

package GADS::Column::File;

use Log::Report 'linkspace';
use MIME::Base64 qw/decode_base64/;
use Moo;
use MooX::Types::MooseLike::Base qw/Int Maybe ArrayRef/;

extends 'GADS::Column';

has '+option_names' => (
    default => sub { 
        +{
            override_types => 0,
        }
    }
);

has override_types => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    builder => sub {
        my $self = shift;
        return [] unless $self->has_options;
        $self->options->{override_types} || [];
    },
    trigger => sub { $_[0]->reset_options },
);

has filesize => (
    is      => 'rw',
    isa     => Maybe[Int],
);

has '+can_multivalue' => (
    default => 1,
);

sub _build_sprefix { 'value' };

# Convert based on whether ID or name provided
sub value_field_as_index
{   my ($self, $value) = @_;
    return 'id' if !$value || $value =~ /^[0-9]+$/;
    return $self->value_field;
}

after build_values => sub {
    my ($self, $original) = @_;
    
    $self->string_storage(1);
    $self->value_field('name');
    my ($file_option) = $original->{file_options}->[0];
    if ($file_option)
    {
        $self->filesize($file_option->{filesize});
    }
};

sub _build_retrieve_fields
{   my $self = shift;
    [qw/name mimetype id/];
}

sub validate
{   my ($self, $value, %options) = @_;
    return 1 if !$value;

    if ($value !~ /^[0-9]+$/ || !$self->schema->resultset('Fileval')->find($value))
    {
        return 0 unless $options{fatal};
        # Check that the file type is allowed here as well
        my $filecheck = GADS::Filecheck->instance;
        $filecheck->check_upload($self->name, $self->content, extra_types => $self->override_types);
        error __x"'{int}' is not a valid file ID for '{col}'",
            int => $value, col => $self->name;
    }
    1;
}

# Any value is valid for a search, as it can include begins_with etc
sub validate_search {1};

sub write_special
{   my ($self, %options) = @_;

    my $id   = $options{id};

    my $foption = {
        filesize => $self->filesize,
    };
    my ($file_option) = $self->schema->resultset('FileOption')->search({
        layout_id => $id,
    })->all;
    if ($file_option)
    {
        $file_option->update($foption);
    }
    else {
        $foption->{layout_id} = $id;
        $self->schema->resultset('FileOption')->create($foption);
    }

    return ();
};

sub tjoin
{   my $self = shift;
    +{$self->field => 'value'};
}

sub cleanup
{   my ($class, $schema, $id)  = @_;
    $schema->resultset('File')->search({ layout_id => $id })->delete;
    $schema->resultset('FileOption')->search({ layout_id => $id })->delete;
};

sub resultset_for_values
{   my $self = shift;
    return $self->schema->resultset('Fileval')->search({
        'files.layout_id' => $self->id,
    }, {
        join => 'files',
        group_by => 'me.name',
    });
}

before import_hash => sub {
    my ($self, $values, %options) = @_;
    my $report = $options{report_only} && $self->id;
    notice __x"Update: filesize from {old} to {new}", old => $self->filesize, new => $values->{filesize}
        if $report && (
            (defined $self->filesize xor defined $values->{filesize})
            || (defined $self->filesize && defined $values->{filesize} && $self->filesize != $values->{filesize})
        );
    $self->filesize($values->{filesize});
};

around export_hash => sub {
    my $orig = shift;
    my ($self, $values) = @_;
    my $hash = $orig->(@_);
    $hash->{filesize} = $self->filesize;
    return $hash;
};

sub import_value
{   my ($self, $value) = @_;

    my $file = $value->{content} && $self->schema->resultset('Fileval')->create_with_file({
        name     => $value->{name},
        mimetype => $value->{mimetype},
        content  => decode_base64($value->{content}),
    });
    $self->schema->resultset('File')->create({
        record_id    => $value->{record_id},
        layout_id    => $self->id,
        child_unique => $value->{child_unique},
        value        => $file && $file->id,
    });
}

1;

