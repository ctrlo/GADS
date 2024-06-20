#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use GADS::DB;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport mode => 'NORMAL';

GADS::DB->setup(schema);

GADS::Config->instance(config => config,);

my $dtf = schema->storage->datetime_parser;

# No site ID configuration and selection, as Record resultset does not contain site_id field
my $rs = schema->resultset('Curval');
while (my $curval = $rs->next)
{
    my $parent_record  = $curval->record;
    my $parent_current = $parent_record->current;
    my $curval_current = $curval->value
        or next;
    $parent_record->createdby
        or next;
    foreach my $curval_record ($curval_current->search_related(
        'records',
        {
            'me.created' => [
                -and => {
                    '>' => $dtf->format_datetime($parent_record->created),
                },
                {
                    '<' => $dtf->format_datetime(
                        $parent_record->created->clone->add(seconds => 60)
                    ),
                },
            ],
            'me.createdby' => $parent_record->createdby->id,
        },
    ))
    {
        # Find audit of parent edit
        my $audit = schema->resultset('Audit')->search({
            user_id => $parent_record->createdby->id,
            url     => [
                "/record/" . $parent_record->current_id,
                { -like => '%/record/%' },
                "/edit/" . $parent_record->current_id,
                { -like => '%/edit/' },
            ],
            method   => 'POST',
            datetime => [
                -and => {
                    '>' => $dtf->format_datetime(
                        $parent_record->created->clone->subtract(
                            seconds => 60
                        )
                    ),
                },
                {
                    '<=' => $dtf->format_datetime($parent_record->created),
                },
            ],
        })->next
            or say STDERR "Cannot find edit of "
            . $parent_record->current_id
            . " edited at "
            . $parent_record->created . " by "
            . $parent_record->createdby->value;

        # Check no direct edit of curval
        $audit = schema->resultset('Audit')->search({
            id      => { '!=' => $audit->id },
            user_id => $parent_record->createdby->id,
            url     => [
                "/record/" . $curval_record->current_id,
                "/edit/" . $curval_record->current_id,
            ],
            method   => 'POST',
            datetime => [
                -and => {
                    '<' => $dtf->format_datetime(
                        $parent_record->created->clone->add(seconds => 60)
                    ),
                },
                {
                    '>=' => $dtf->format_datetime($parent_record->created),
                },
            ],
        })->next
            and say STDERR "DIRECT EDIT!";
        say STDERR "Parent "
            . $parent_record->current_id
            . " edited "
            . $parent_record->created . " by "
            . $parent_record->createdby->value
            . " has nearby curval record edited at "
            . $curval_record->created . " by "
            . $curval_record->createdby->value
            . " with ID "
            . $curval_record->current_id;
    }
}

