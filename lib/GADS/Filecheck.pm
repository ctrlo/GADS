package GADS::Filecheck;

use strict;
use warnings;

use File::LibMagic;
use Log::Report 'linkspace';

use Moo;

with 'MooX::Singleton';

# Only load magic library once
my $magic = File::LibMagic->new;

sub get_filetype {
    my ($self, $path) = @_;
    my $info = $magic->info_from_filename($path);
    return $info->{mime_type};
}

sub is_image
{   my ($self, $upload) = @_;
    my $info = $magic->info_from_filename($upload->tempname);
    $info->{mime_type} =~ m!^image/!;
}

sub check_upload
{   my ($self, $name, $file, %options) = @_;

    my $check_name = $options{check_name} // 1;
    my $allowed_data = $options{extra_types};

    my $info = $magic->info_from_filename($file);

    my ($mimeRegex, $filetypeRegex) = $self->create_regex($allowed_data);

    my $allowed_bypass = $info->{mime_type} =~ qr/$mimeRegex/ if $mimeRegex;

    error __x"Files of mimetype {mimetype} are not allowed",
        mimetype => $info->{mime_type}
            unless $allowed_bypass or $self->check_type($info->{mime_type});
    
    $self->check_filename($name, $filetypeRegex);

    $self->check_name($name)
        if($check_name);

    return $info->{mime_type};
}

sub create_regex
{   my ($self, $allowed_data) = @_;

    # We need to check the allowed data is defined rather than checking for an array
    return (undef, undef) unless $allowed_data;

    my @mimeRegexes = map { qr!\Q$_->{name}\E! } @$allowed_data;
    my @filetypeRegexes = map { qr!\Q$_->{extension}\E! } @$allowed_data;

    my $mimeRegex = '^(' . join ('|', @mimeRegexes) . ')$';
    my $filetypeRegex = '^(' . join ('|', @filetypeRegexes) . ')$';

    return (qr/$mimeRegex/, qr/$filetypeRegex/);
}

sub check_filename
{   my ($self, $filename, $filetypeRegex) = @_;

    $filename =~ /\.([a-z]+)$/i
        or error __"Files without extensions cannot be uploaded";
    my $ext = $1;
    my $extension_bypass = $ext =~ $filetypeRegex if $filetypeRegex;
    error __x"Files with extension of {ext} are not allowed", ext => $ext
        unless $extension_bypass or $self->check_extension($ext);
}

sub check_file
{
    my ($self, $upload, %options) = @_;

    return $self->check_upload($upload->filename, $upload->tempname, %options);
}

sub check_name { 
    my ($self, $filename) = @_;
    error __x"The filename {name} is not allowed. Filenames can only contain alphanumeric characters and a single dot",
        name => $filename
            unless $filename =~ /^[-+_ a-zA-Z0-9\(\)]{1,200}\.[a-zA-Z0-9]{1,10}$/;
}

sub check_type {
    my ($self, $mime_type) = @_;
    my $result = $mime_type =~ m!^
                (text/|image/|video/|audio/|application/x-abiword
                |application/msword|application/vnd\.openxmlformats-officedocument\.wordprocessingml\.document
                |application/vnd\.oasis\.opendocument\.presentation
                |application/vnd\.oasis\.opendocument\.spreadsheet
                |application/vnd\.oasis\.opendocument\.text|application/pdf
                |application/vnd\.ms-powerpoint
                |application/vnd\.openxmlformats-officedocument\.presentationml\.presentation
                |application/rtf|application/vnd\.ms-excel
                |application/vnd\.openxmlformats-officedocument\.spreadsheetml\.sheet
                |application/json
            )!xi;
    !!$result
}

sub check_extension {
    my ($self, $ext) = @_;

    my $result = $ext =~ /^(doc|docx|pdf|jpeg|jpg|png|wav|rtf|xls|xlsx|ods|ppt|pptx|odf|odg|odt|ott|sda|sdc|sdd|sdw|sxc|sxw|odp|sdp|csv|txt|msg|tif|svg)$/i;

    !!$result
}

1;
