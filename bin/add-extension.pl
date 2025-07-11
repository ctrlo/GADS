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
use GADS::Filecheck;

use Dancer2::Plugin::LogReport 'linkspace';

my ( $mimetype, $extension, $instance, $layout_id );

GetOptions(
    'mimetype=s'  => \$mimetype,
    'extension=s' => \$extension,
    'instance=i'  => \$instance,
    'layout=i'    => \$layout_id
);

unless ( $mimetype && $extension && $instance && $layout_id ) {
    say "Usage $0 --mimetype=<mimetype> --extension=<extension> --layout=<layout_id> --instance=<instance_id>";
    exit 1;
}

# we need a config instance, and a filecheck instance
GADS::Config->instance( config => config );
my $file_check = GADS::Filecheck->instance();

# Check against the already allowed mime-types and error if it already exists
if ( $file_check->check_type($mimetype) ) {
    error __x"Mimetype {type} already allowed", type=>$mimetype;
    exit 2;
}

# Check against the already allowed extensions and error if it already exists
if ( $file_check->check_extension($extension) ) {
    error __x"Extension {extension} already allowed", extension=>$extension;
    exit 3;
}

# We're doing this server-side as admin, therefore we don't worry about permissions
$GADS::Schema::IGNORE_PERMISSIONS = 1;


# Get the layout by instance ID
my $layout = GADS::Layout->new(
    user_permission_override => 1,
    user                     => undef,
    instance_id              => $instance,
    config                   => config,
    schema                   => schema,
);

# Get the column
my $result     = $layout->column($layout_id);

# Check if the column is of the correct type - there's no point setting this property on the wrong one!
if ( $result->type ne 'file' ) {
    error __x"Invalid column for properties to be set on";
    exit 4;
}

# Make sure the user wants to add the data to the selected column.
print "Do you want to add mime type $mimetype with extension $extension to ". $result->name ." (y/n): ";
my $answer = <STDIN>;

# Do a check for y
if ( $answer =~ /^y/i ) {
    my $type = +{
        'name'      => $mimetype,
        'extension' => $extension,
    };
    $result->override_types([]) unless $result->override_types;
    my $types = $result->override_types;
    push(@$types, $type) unless grep { $_->{extension} eq $type->{extension} && $_->{name} eq $type->{name} } @$types;
    $result->override_types($types);
    $result->write;
    print "Extension and mime type added\n\n";
} else {
    print "Addition of extension cancelled\n\n";
}

# Ensure a zero exit code (all errors have an attached number in case this script is used within other scripts)
exit 0;
