=pod
GADS - Globally Accessible Data Store
Copyright (C) 2014 Ctrl O Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

package GADS::Datum::Code;

use String::CamelCase qw(camelize); 
use Safe;
use Log::Report;
use Moo;
use namespace::clean;

extends 'GADS::Datum';

has force_update => (
    is      => 'rw',
    trigger => sub {
        my $self = shift;
        $self->clear_value;
    },
);

has schema => (
    is       => 'rw',
    required => 1,
);

sub write_cache
{   my ($self, $table, $value) = @_;

    my $tablec = camelize $table;
    # The cache tables have unqiue constraints to prevent
    # duplicate cache values for the same records. Using an eval
    # catches any attempts to write duplicate values.
    try {
        $self->schema->resultset($tablec)->create({
            record_id => $self->record_id,
            layout_id => $self->column->{id},
            value     => $value,
        });
    };
    # Log any messages from try block, but only as trace
    $@->reportAll(reason => 'TRACE');
    $value;
}

sub sub_date
{   my ($self, $code, $field, $date) = @_;
    trace "Entering sub_date";
    my $subs = 0; # Number of substitutions made
    # Try epoch, year, month and day
    $field =~ /^(\[?)(.*?)(\]?)$/;
    my ($begin, $name, $end) = ($1 || "", $2, $3 || "");
    my $year = $date ? $date->year : qq("");
    $subs += $code =~ s/\Q$begin$name.year$end/$year/gi;
    my $month = $date ? $date->month : qq("");
    $subs += $code =~ s/\Q$begin$name.month$end/$month/gi;
    my $day = $date ? $date->day : qq("");
    $subs += $code =~ s/\Q$begin$name.day$end/$day/gi;
    my $epoch = $date ? $date->epoch : qq("");
    $subs += $code =~ s/\Q$begin$name$end/$epoch/gi;
    wantarray ? ($code, $subs) : $code;
}

sub sub_values
{   my ($self, $col, $code) = @_;

    trace "Entering sub_values";

    my $dvalue = $self->dependent_values->{$col->id};
    my $name   = $col->name;

    if ($dvalue && $col->type eq "date")
    {
        $code = $self->sub_date($code, "[$name]", $dvalue->value);
    }
    elsif ($col->type eq "daterange")
    {
        # Return empty strings for missing values, otherwise eval fails after
        # substitutions have been made
        $dvalue = {
            from  => $dvalue ? $dvalue->from_dt    : undef,
            to    => $dvalue ? $dvalue->to_dt      : undef,
            value => $dvalue ? '"'.$dvalue->as_string.'"' : qq(""),
        };
        # First try subbing in full value
        $code =~ s/\Q[$name.value]/$dvalue->{value}/gi;
        # The following code returns if a substitution of a blank value was made
        # This will become a grey value for RAG fields
        my $subs;
        ($code, $subs) = $self->sub_date($code, "[$name.from]", $dvalue->{from});
        return if $self->column->type eq "rag" && $subs && !$dvalue->{from};
        ($code, $subs) = $self->sub_date($code, "[$name.to]", $dvalue->{to});
        return if $self->column->type eq "rag" && $subs && !$dvalue->{to};
    }
    elsif ($col->type eq "tree" && $code =~ /\Q[$name.level\E([0-9]+)\]/)
    {
        # Need to loop round in case more than one level
        while ($code =~ /\Q[$name.level\E([0-9]+)\]/)
        {
            my $level = $1;
            my $rvalue;
            if ($dvalue && $dvalue->deleted)
            {
                $rvalue = "Orphan node (deleted)";
            }
            elsif ($dvalue)
            {
                my @ancestors  = $dvalue->id ? $col->node($dvalue->id)->{node}->{node}->ancestors : ();
                my $get_level  = $level + 1; # Root is first, add one to ignore
                my $level_node = @ancestors == $get_level - 1 # Return current node if it's that level
                               ? $dvalue->id
                               : $ancestors[-$get_level] # Otherwise check it exists
                               ? $ancestors[-$get_level]->name
                               : undef;
                $rvalue        = $level_node ? $col->node($level_node)->{value} : undef;
            }
            $rvalue = $rvalue ? "q`$rvalue`" : qq("");
            $code =~ s/\Q[$name.level$level]/$rvalue/gi;
        }
    }

    # Possible for tree values to have both a level (above code) or be on
    # their own (below code)
    unless ($col->type eq "date" || $col->type eq "daterange")
    {
        # XXX Is there a q char delimiter that is safe regardless
        # of input? Backtick is unlikely to be used...
        if ($col->numeric)
        {
            # If field is numeric but does not have numeric value, then return
            # grey, otherwise the value will be treated as zero
            # and will probably return misleading RAG values
            no warnings 'numeric', 'uninitialized';
            $dvalue .= ""; # Stringify
            return if $self->column->type eq "rag" && $dvalue eq '';
            $dvalue = int $dvalue;
        }
        else {
            # Quote for the eval
            $dvalue = $dvalue ? "q`$dvalue`" : qq("");
        }
        $code =~ s/\Q[$name]/$dvalue/gi;
    }

    $code;
}

sub safe_eval
{
    my($self, $expr) = @_;
    my($cpt) = new Safe;

    #Basic variable IO and traversal
    $cpt->permit_only(qw(null scalar const padany lineseq leaveeval rv2sv pushmark list return enter stub));
    
    #Comparators
    $cpt->permit(qw(not lt i_lt gt i_gt le i_le ge i_ge eq i_eq ne i_ne ncmp i_ncmp slt sgt sle sge seq sne scmp));

    # XXX fix later? See https://rt.cpan.org/Public/Bug/Display.html?id=89437
    $cpt->permit(qw(rv2gv));

    # Base math
    $cpt->permit(qw(preinc i_preinc predec i_predec postinc i_postinc postdec i_postdec int hex oct abs pow multiply i_multiply divide i_divide modulo i_modulo add i_add subtract i_subtract negate i_negate));

    #Conditionals
    $cpt->permit(qw(cond_expr flip flop andassign orassign and or xor));

    # String functions
    $cpt->permit(qw(concat substr index));

    # Regular expression pattern matching
    $cpt->permit(qw(match));

    #Advanced math
    #$cpt->permit(qw(atan2 sin cos exp log sqrt rand srand));

    my($ret) = $cpt->reval($expr);

    if($@)
    {
        die $@;
    }
    else {
        return $ret;
    }
}

1;

