#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2;
use Dancer2::Plugin::DBIC;
use Getopt::Long;
use Text::CSV;
use feature 'say';

my ($action);

GetOptions(
    'action=s'   => \$action
) or exit;

$action or die "ERROR: Please state if you want to import/export group permissions with --action";

if ($action eq 'import') {
    Import_permissions();
}
elsif ($action eq 'export') {
    Export_permissions();
}
else {
    die "ERROR: You must either import or export within --action";
}

sub Import_permissions {
    say "Enter the file you want to import from:";
    my $file = <STDIN>;
    chomp($file);

    -f $file or die "ERROR: File '$file' does not exist";

    $file or die "Usage: $0 filename";
    my $csv = Text::CSV->new({ binary => 1 })
    or die "Cannot use CSV: ".Text::CSV->error_diag ();
    open my $fh, "<:encoding(utf8)", $file or die "$file: $!";
    my $guard = schema->txn_scope_guard;
     
    while (my $row = $csv->getline($fh)) {
        my ($layout_id, $group_id, $permission) = @$row;
        my $RowCount = $csv->record_number;
        
        unless (defined $layout_id && $layout_id =~ /^\d+$/) {
            die "ERROR: Invalid Layout ID '$layout_id' on row $RowCount.\n";
        }
        unless (defined $group_id && $group_id =~ /^\d+$/) {
            die "ERROR: Invalid Group ID '$group_id' on row $RowCount.\n";
        }
        unless (defined $permission && $permission =~ /^(?:read|write_new|write_existing|write_existing_no_approval|write_new_no_approval)$/) {
            die "ERROR: Invalid Permission '$permission' on row $RowCount. Value must be read, write_new, write_existing, or write_existing_no_approval.\n";
        }
            
        rset('Layout')->find($layout_id) or die "ERROR: Layout ID '$layout_id' does not exist\n";
        rset('Group')->find($group_id)   or die "ERROR: Group ID '$group_id' does not exist\n";
            
        my $existing = rset('LayoutGroup')->find({
            layout_id  => $layout_id,
            group_id   => $group_id,
            permission => $permission
        });
        
        if ($existing) {
            say "Skipping permission '$permission' for group '$group_id' on layout '$layout_id' because this permission already exists";
            next;
        }
        
        rset('LayoutGroup')->create({
		        layout_id  => $layout_id,
		        group_id   => $group_id,
		        permission => $permission,
        });
        say "Will add permission '$permission' to group '$group_id' for layout '$layout_id'";
    }
    $guard->commit;
    say "Import complete";
}

sub Export_permissions {
    my $export_file = './Group_permission_export.csv';
    ! -f $export_file or die "ERROR: $export_file already exists, unable to overwrite file!";
    say "Enter the group IDs you're looking to export (e.g. 1,2,3): ";
    my $input = <STDIN>;
    chomp($input);

    if (!$input || $input !~ /^\s*\d+(?:\s*,\s*\d+)*\s*$/) {
        die "Error: You need to enter a number or a comma-separated list of numbers.\n";
    }
 
    my @groups = split(/\s*,\s*/, $input);

    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });
    open my $fh, ">:encoding(utf8)", $export_file or die "$export_file: $!";
    
    my @layout_groups = rset('LayoutGroup')->search(
        {
            'me.group_id' => { '-in' => \@groups },
        },
        {
            prefetch => [ 'layout' ],
        }
    )->all;
    
    $csv->say($fh, [ 'Instance ID','Layout Name','Layout ID', 'Group ID','Permission' ]);
    
    foreach my $lg (@layout_groups) {
        my $layout      = $lg->layout;
        my $instance_id = $layout->instance_id;
        my $layout_name = $layout->name ;
        my $group_id    = $lg->group_id;
        my $layout_id   = $lg->layout_id;
        my $permission  = $lg->permission;

        $csv->say($fh, [ $instance_id, $layout_name, $layout_id, $group_id, $permission ]);
    }
    close($fh);
    say "Successfully exported permissions to '$export_file'";
}
