#!/bin/perl

use warnings;
use strict;

use feature 'say';

use FindBin qw($Bin);

use lib "$Bin/../lib";

use Getopt::Long;

use Dancer2;
use Dancer2::Plugin::DBIC;

use GADS::Schema;
use GADS::Layout;
use GADS::Config;
use GADS::Filecheck;

use Dancer2::Plugin::LogReport 'linkspace';

dispatcher close => 'error_handler';

my ( $mimetype, $extension, $instance, $layout_id );

GetOptions(
    'mimetype=s'  => \$mimetype,
    'extension=s' => \$extension,
    'instance=i'  => \$instance,
    'layout=i'    => \$layout_id
);

unless ( $mimetype && $extension && $instance && $layout_id ) {
    report ERROR => __x"Usage {command} --mimetype=<mimetype> --extension=<extension> --layout=<layout_id> --instance=<instance_id>", command => $0;
}

# we need a config instance, and a filecheck instance
GADS::Config->instance( config => config );
my $file_check = GADS::Filecheck->instance();

# Check against the already allowed mime-types and error if it already exists
if ( $file_check->check_type($mimetype) ) {
    report ERROR => __x"Mimetype {type} already allowed", type=>$mimetype;
}

# Check against the already allowed extensions and error if it already exists
if ( $file_check->check_extension($extension) ) {
    report ERROR => __x"Extension {extension} already allowed", extension=>$extension;
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
    report ERROR => __"Invalid column for properties to be set on";
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
    notice __"Extension and mime type added";
} else {
    notice __"Addition of extension cancelled";
}
