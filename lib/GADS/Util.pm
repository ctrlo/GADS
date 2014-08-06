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

    return undef unless $record;

    my $field = 'field'.$column->{id};

    # By default, return the actual end value. If raw is specified,
    # return the raw value, suitable for use in a HTML form:
    # - the ID for an enum
    # - the ymd for a date
    # - the ID for a tree
    # - standard value for other fields
    # Returns undef for missing values
    my $raw   = $options->{raw};
    my $blank = $raw ? undef : '';

    # If prefilled from previous form submission (with errors), values
    # will be in a hash
    return $record->{$field}->{value}
        if $raw && ref $record eq 'HASH';

    if ($column->{type} eq "rag")
    {
        return GADS::Record->rag($column, $record);
    }
    elsif ($column->{type} eq "calc")
    {
        return GADS::Record->calc($column, $record);
    }
    elsif ($column->{type} eq "person")
    {
        if ($raw)
        {
            return $record->$field ? $record->$field->value->id : undef;
        }
        return GADS::Record->person($column, $record);
        my $firstname = $record->$field ? $record->$field->value->firstname : '';
        my $surname   = $record->$field ? $record->$field->value->surname : '';
        return "$surname, $firstname";
    }
    elsif ($column->{type} eq "enum" || $column->{type} eq 'tree')
    {
        if ($raw)
        {
            return $record->$field && $record->$field->value ? $record->$field->value->id : $blank;
        }
        return $record->$field && $record->$field->value ? $record->$field->value->value : $blank;
    }
    elsif ($column->{type} eq "date")
    {
        if ($raw)
        {
            return $record->$field ? $record->$field->value->ymd : undef;
        }
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
    elsif ($column->{type} eq "file")
    {
        if ($record->$field)
        {
            my $filename = $record->$field->value->name;
            return $filename if $options->{download};
            my $id = $record->$field->value->id;
            return qq(<a href="/file/$id">$filename</a>);
        }
        else {
            return '';
        }
    }
    else
    {
        return $record->$field ? $record->$field->value : $blank;
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

