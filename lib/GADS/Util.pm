use warnings;
use strict;

package GADS::Util;
use base 'Exporter';
use Regexp::Common "URI";
use HTML::Entities;

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

sub _date
{
    my ($date, $options) = @_;

    # Whether to only select some fields from the date value
    if ($options->{date_fields})
    {
        my $include;
        foreach my $k (keys $options->{date_fields})
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

sub item_value
{
    my ($column, $record, $options) = @_;

    return undef unless $record;

    # Check for special case of ID
    return $record->current_id if $column->{type} eq "id";

    my $field = 'field'.$column->{id};

    # By default, return the actual end value. If raw is specified,
    # return the raw value, suitable for use in a HTML form:
    # - the ID for an enum
    # - the ymd for a date
    # - the ID for a tree
    # - standard value for other fields
    # Returns undef for missing values
    my $raw    = $options->{raw};
    my $blank  = $raw ? undef : '';
    my $encode = $options->{encode_entities};

    # XXX This is all starting to get a bit messy. Probably time for
    # a rewrite. If prefilled from previous form submission (with errors)
    # or if remembered values, then values will be in a hash.
    if (ref $record eq 'HASH')
    {
        return unless $raw;
        # If the key doesn't exist, return undef, as that means
        # there is no remember value for it. In the case of
        # a person, this will allow the form to be pre-populated
        # with the current user
        if (exists $record->{$field}->{value})
        {
            # If the key does it exist, but it's undef, then
            # it's a "blank" person value, in which case return
            # an empty string, so as to set the selection as blank
            # (and not default to current user)
            return $record->{$field}->{value} // '';
        }
        else {
            return undef;
        }
    }

    if ($column->{type} eq "rag")
    {
        return GADS::Record->rag($column, $record);
    }
    elsif ($column->{type} eq "calc")
    {
        my $v = GADS::Record->calc($column, $record);
        if ($column->{return_format} && $column->{return_format} eq "date")
        {
            my $date = eval {DateTime->from_epoch(epoch => $v)}
                or return;
            return _date $date, $options;
        }
        else {
            return $v;
        }
    }
    elsif ($column->{type} eq "person")
    {
        if ($raw)
        {
            return $record->$field && $record->$field->value ? $record->$field->value->id : '';
        }
        my $v = GADS::Record->person($column, $record);
        $v = $encode ? encode_entities($v) : $v;
        return $v if $options->{plain};
        my $person = $record->$field && $record->$field->value ? $record->$field->value : undef;
        return $person ? GADS::Record->person_popover($person) : '';
    }
    elsif ($column->{type} eq "enum" || $column->{type} eq 'tree')
    {
        if ($raw)
        {
            return $record->$field && $record->$field->value ? $record->$field->value->id : $blank;
        }
        my $v = $record->$field && $record->$field->value ? $record->$field->value->value : $blank;
        return $encode ? encode_entities($v) : $v;
    }
    elsif ($column->{type} eq "date")
    {
        if ($raw)
        {
            return $record->$field && $record->$field->value ? $record->$field->value->ymd : undef;
        }
        my $date = $record->$field ? $record->$field->value : '';
        $date or return '';

        return _date $date, $options;
    }
    elsif ($column->{type} eq "daterange")
    {
        my $date = $record->$field && $record->$field->from && $record->$field->to
                 ? {from => $record->$field->from, to => $record->$field->to}
                 : undef;
        $date or return;

        # Whether to only select some fields from the date value
        if ($options->{date_fields})
        {
            my $include_from; my $include_to;
            foreach my $k (keys $options->{date_fields})
            {
                $include_from->{$k} = $date->$k;
                $include_to->{$k}   = $date->$k;
            }
            $date = {from => DateTime->new($include_from), to => DateTime->new($include_to)};
        }

        if ($options->{epoch})
        {
            return {from => $date->{from}->epoch, to => $date->{to}->epoch};
        }
        elsif (my $f = $options->{strftime})
        {
            return {from => $date->{from}->strftime($f), to => $date->{to}->strftime($f)};
        }
        elsif ($options->{raw})
        {
            return {from => $date->{from}->ymd, to => $date->{to}->ymd};
        }
        else {
            return GADS::Record->daterange($column, $record);
        }
    }
    elsif ($column->{type} eq "file")
    {
        if ($record->$field)
        {
            return unless $record->$field->value;
            my $filename = $record->$field->value->name;
            $filename = $encode ? encode_entities($filename) : $filename;
            return $filename if $options->{plain};
            my $id = $record->$field->value->id;
            return qq(<a href="/file/$id">$filename</a>);
        }
        else {
            return;
        }
    }
    elsif ($column->{type} eq "string")
    {
        my $string = $record->$field ? $record->$field->value : $blank;
        $string = $encode ? encode_entities($string) : $string;
        return $string if $raw || $options->{plain};
        $string =~ s( ($RE{URI}{HTTP}{-scheme => qr/https?/}) ) (<a href="$1">$1</a>)gx
            if $string;
        $string;
    }
    else {
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

