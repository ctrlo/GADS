use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# Tests to check that subrecords for a record in draft are always returned to
# the user when reloading the draft, regardless of any view limits
my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;

my $sheet   = Test::GADS::DataSheet->new(
    schema           => $schema,
    curval           => 2,
    calc_return_type => 'string',
    calc_code        => qq{function evaluate (_id)
        -- Just return a constant that can be matched in a filter
        return "foobar"
    end},
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;
my $user = $sheet->user_normal1;
$layout->user($user);
$curval_sheet->layout->user($user);

# Set up curval to be allow adding and removal
my $curval = $columns->{curval1};
$curval->show_add(1);
$curval->value_selector('noshow');
$curval->write(no_alerts => 1, force => 1);

# Save draft
my $record = GADS::Record->new(
    user   => $user,
    layout => $layout,
    schema => $schema,
);
$record->initialise(instance_id => $layout->instance_id);

my $curval_datum = $record->fields->{$curval->id};
my $curval_string = $curval_sheet->columns->{string1};
my $params = $curval_string->field."=foo10";
$curval_datum->set_value([$params]);
$record->fields->{$columns->{integer1}->id}->set_value(10); # Prevent calc warnings
$record->write(draft => 1);

# Add a view limit
my $rules = GADS::Filter->new(
    as_hash => {
        rules     => [{
            id       => $curval_sheet->columns->{calc1}->id,
            type     => 'string',
            value    => 'foobar',
            operator => 'equal',
        }],
    },
);

my $view_limit = GADS::View->new(
    name        => 'Limit to view',
    filter      => $rules,
    instance_id => 2,
    layout      => $curval_sheet->layout,
    schema      => $schema,
    user        => $user,
);
$view_limit->write;
$user->set_view_limits([$view_limit->id]);

# Reload
$record->clear;
$record->load_remembered_values(instance_id => $layout->instance_id);
$curval_datum = $record->fields->{$curval->id};
ok(!$curval_datum->blank, "New draft value not blank");
my ($form_values) = @{$curval_datum->html_form};
like($form_values->{as_query}, qr/$params/, "Correct first record for exclusive to" );

done_testing();
