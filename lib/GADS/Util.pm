use warnings;
use strict;

package GADS::Util;
use base 'Exporter';

my @permissions = qw/
  UPDATE
  UPDATE_NONEED_APPROVAL
  CREATE
  CREATE_NONEED_APPROVAL
  APPROVER
  ADMIN
  OPEN
  APPROVE
  READONLY

  item_value
  item_id
 /;

# push @listconfig, qw(format_email format_from_html format_from_plain format_from_mailto);
our @EXPORT_OK   = (@permissions);
our %EXPORT_TAGS =
  ( permissions => \@permissions
  , all         => \@EXPORT_OK
  );

use Carp;
# listconfig moderate values
use constant
  { #### User permissions
    UPDATE                 => 1   # update records without approval
  , UPDATE_NONEED_APPROVAL => 2   # update records with approval
  , CREATE                 => 4   # create new records without approval
  , CREATE_NONEED_APPROVAL => 8   # create new records with approval
  , APPROVER               => 16  # Approve update requests
  , ADMIN                  => 32  # Administrator
    #### Field permissions
  , OPEN                   => 0   # Open access, anyone can write
  , APPROVE                => 1   # Approval needed for writes
  , READONLY               => 2   # Read-only field
  };

sub item_value
{
    my ($column, $record, $options) = @_;

    my $field = 'field'.$column->{id};
    if ($column->{type} eq "rag")
    {
        return GADS::Record->rag($column->{rag}, $record);
    }
    elsif ($column->{type} eq "calc")
    {
        return GADS::Record->calc($column->{calc}, $record);
    }
    elsif ($column->{type} eq "person")
    {
        my $firstname = $record->$field ? $record->$field->value->firstname : '';
        my $surname   = $record->$field ? $record->$field->value->surname : '';
        return "$surname, $firstname";
    }
    elsif ($column->{type} eq "enum" || $column->{type} eq 'tree')
    {
        return $record->$field ? $record->$field->value->value : '';
    }
    elsif ($column->{type} eq "date")
    {
        my $date = $record->$field ? $record->$field->value : '';
        $date or return '';

        if ($options->{only})
        {
            my $include;
            foreach my $k (keys $options->{only})
            {
                $include->{$k} = $date->$k;
            }
            $date = DateTime->new($include);
        }

        if ($options->{epoch})
        {
            return $date->epoch;
        }
        elsif (my $f = $options->{strftime})
        {
            return $date->strftime($f);
        }
        else {
            return $date->ymd;
        }
    }
    else
    {
        return $record->$field ? $record->$field->value : '';
    }
}


sub item_id
{
    my ($column, $record) = @_;
    my $field = 'field'.$column->{id};
    if ($column->{type} eq "rag")
    {
        return GADS::Record->rag($column->{rag}, $record);
    }
    elsif ($column->{type} eq "person")
    {
        return $record->$field ? $record->$field->value->id : undef;
    }
    elsif ($column->{type} eq "enum" || $column->{type} eq 'tree')
    {
        return $record->$field ? $record->$field->value->id : undef;
    }
    elsif ($column->{type} eq "date")
    {
        return $record->$field ? $record->$field->value->id : undef;
    }
    else
    {
        return $record->$field ? $record->$field->value : undef;
    }
}

1;

