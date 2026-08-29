#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2;
use Dancer2::Plugin::DBIC;
use Getopt::Long;
use Text::CSV;
use feature 'say';
use Log::Report syntax => 'LONG';

my ($action, $file);

GetOptions(
    'action=s' => \$action,
    'file=s'   => \$file
) or exit;

$action or report ERROR => "Please state if you want to import/export group permissions with --action";
$file or report ERROR => "Please provide the file you want to import/export to/from with --file";
if ($action eq 'import') {
    Import_permissions();
}
elsif ($action eq 'export') {
    Export_permissions();
}
else {
    report ERROR => "You must state if you want to import or export with --action";
}


sub Import_permissions {

    -f $file or report ERROR => "File '{file}' does not exist", file => $file;

    my $csv = Text::CSV->new({ binary => 1 })
        or report ERROR => "Cannot use CSV: ".Text::CSV->error_diag ();
    open my $fh, "<:encoding(utf8)", $file or report FAULT => "Unable to open file {file}", file => $file;
    my $guard = schema->txn_scope_guard;
    
    my $headers = $csv->getline($fh);
    $csv->column_names(@$headers) if $headers;
    
    report ERROR => "Invalid CSV header/s. Import must consist of 3 columns: layout_id, group_id and permission" 
       unless $headers && join(',', sort @$headers) eq 'group_id,layout_id,permission';

    while (my $row = $csv->getline_hr($fh)) {
	    
    my $RowCount = $csv->record_number;
	my $layout_id = $row->{layout_id}; 
	my $group_id = $row->{group_id};
	my $permission = $row->{permission};

        unless (defined $layout_id && $layout_id =~ /^\d+$/) {
            report ERROR =>  "ERROR: Invalid Layout ID '$layout_id' on row $RowCount.";
        }
        unless (defined $group_id && $group_id =~ /^\d+$/) {
            report ERROR =>  "ERROR: Invalid Group ID '$row->{group_id}' on row $RowCount.";
        }
        unless (defined $permission && $permission =~ /^(?:read|write_new|write_existing|write_existing_no_approval|write_new_no_approval)$/) {
             report ERROR => "Invalid Permission '$permission' on row $RowCount. Value must be read, write_new, write_existing, or write_existing_no_approval.";
        }
            
        rset('Layout')->find($layout_id) or report ERROR => "Layout ID '$layout_id' does not exist\n";
        rset('Group')->find($group_id)   or report ERROR => "Group ID '$group_id' does not exist\n";
            
        my $existing = rset('LayoutGroup')->find({
            layout_id  => $layout_id,
            group_id   => $group_id,
            permission => $permission
        });
        
        if ($existing) {
            info "Skipping permission '$permission' for group '$group_id' on layout '$layout_id' because this permission already exists";
            next;
        }
        
        rset('LayoutGroup')->create({
		        layout_id  => $layout_id,
		        group_id   => $group_id,
		        permission => $permission,
        });
        info "Will add permission '$permission' to group '$group_id' for layout '$layout_id'";
    }
    $guard->commit;
    info "Import complete";
}

sub Export_permissions {
    ! -f $file or report ERROR => "$file already exists, unable to overwrite file!";
    say "Enter the group IDs you're looking to export (e.g. 1,2,3): ";
    my $input = <STDIN>;
    chomp($input);

    if (!$input || $input !~ /^\s*\d+(?:\s*,\s*\d+)*\s*$/) {
        report ERROR => "You need to enter a number or a comma-separated list of numbers.\n";
    }
 
    my @groups = split(/\s*,\s*/, $input);

    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });
    open my $fh, ">:encoding(utf8)", $file or report FAULT => "$file";
    
    my @layout_groups = rset('LayoutGroup')->search(
        {
            'me.group_id' => { '-in' => \@groups },
        },
        {
            prefetch => [ 'layout' ],
        }
    )->all;
    
    $csv->say($fh, [ 'instance_id','layout_name','layout_id','group_id','permission' ]);
    
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
    info "Successfully exported permissions to '$file'";
}
