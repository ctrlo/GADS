#!/bin/perl

use warnings;
use strict;

use feature 'say';

use FindBin qw($Bin);

use lib "$Bin/../lib";

use Getopt::Long;
use JSON qw(decode_json encode_json);

use Dancer2;
use Dancer2::Plugin::DBIC;

use GADS::Schema;
use GADS::Layout;
use GADS::Config;

GADS::Config->instance( config => config );

my ( $mimetype, $extension, $instance, $layout );

GetOptions(
    'mimetype=s'  => \$mimetype,
    'extension=s' => \$extension,
    'instance=i'  => \$instance,
    'layout=i'    => \$layout
);

unless ( $mimetype && $extension && $instance && $layout ) {
    say
"Usage $0 --mimetype=<mimetype> --extension=<extension> --instance=<instance_id> --layout=<layout_id>";
    exit 1;
}

if (
    $mimetype =~ m!^
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
            )!xi
  )
{
    say "Mimetype $mimetype already allowed";
    exit 2;
}

if ( $extension =~
/^(doc|docx|pdf|jpeg|jpg|png|wav|rtf|xls|xlsx|ods|ppt|pptx|odf|odg|odt|ott|sda|sdc|sdd|sdw|sxc|sxw|odp|sdp|csv|txt|msg|tif|svg)$/i
  )
{
    say "Extension $extension already allowed";
    exit 3;
}

$GADS::Schema::IGNORE_PERMISSIONS = 1;

my $l = GADS::Layout->new(
    user_permission_override => 1,
    user                     => undef,
    instance_id              => $instance,
    config                   => config,
    schema                   => schema,
);

my @all_fields = $l->all;
my $result     = [ grep { $_->id == $layout } @all_fields ]->[0];

unless ( ref($result) eq "GADS::Column::File" ) {
    say "Invalid column for properties to be set on";
    exit 4;
}

say "Field "
  . $result->name
  . " with ID "
  . $result->id
  . " is a "
  . ref($result);
print "Do you want to add mime type $mimetype with extension $extension (y/n): ";
my $answer = <STDIN>;
if ( $answer =~ /^y/i ) {
    my $type = +{
        'name' => $mimetype,
        'extension' => $extension,
    };
    $result->extra_values([]) unless $result->extra_values;
    push(@{$result->extra_values}, $type);
    $result->write;
}

exit 0;
