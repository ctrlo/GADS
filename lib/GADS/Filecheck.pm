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

sub check_file
{   my ($self, $upload) = @_;

    my $info = $magic->info_from_filename($upload->tempname);

    error __x"Files of mimetype {mimetype} are not allowed",
        mimetype => $info->{mime_type}
            unless $info->{mime_type} =~ m!^
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

    $upload->filename =~ /\.([a-z]+)$/i
        or error __"Files without extensions cannot be uploaded";
    my $ext = $1;
    error __x"Files with extension of {ext} are not allowed", ext => $ext
        unless $ext =~ /^(doc|docx|pdf|jpeg|jpg|png|wav|rtf|xls|xlsx|ods|ppt|pptx|odf|odg|odt|ott|sda|sdc|sdd|sdw|sxc|sxw|odp|sdp|csv|txt|msg|tif|svg)$/i;

    # As recommended at https://owasp.org/www-community/vulnerabilities/Unrestricted_File_Upload
    error __x"The filename {name} is not allowed. Filenames can only contain alphanumeric characters and a single dot",
        name => $upload->filename
            unless $upload->filename =~ /[-+_ a-zA-Z0-9]{1,200}\.[a-zA-Z0-9]{1,10}/;

    error __"Maximum file size is 5 MB"
        if $upload->size > 5 * 1024 * 1024;

    return $info->{mime_type};
}

1;
