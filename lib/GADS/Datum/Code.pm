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

use Data::Dumper;
use GADS::Safe;
use String::CamelCase qw(camelize); 
use Tree::DAG_Node;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;
use namespace::clean;

extends 'GADS::Datum';

after 'set_value' => sub {
    my $self = shift;
    $self->_set_has_value(1);
};

has value => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
    coerce  => sub {
        my $values = shift;
        # If the timezone is floating, then assume it is UTC (e.g. from MySQL
        # database which do not have timezones stored). Set it as UTC, as
        # otherwise any changes to another timezone will not make any effect
        foreach my $v (@$values)
        {
            $v->time_zone->is_floating && $v->set_time_zone('UTC')
                if ref $v eq 'DateTime';
            $v->start->time_zone->is_floating && $v->set_time_zone('UTC')
                if ref $v eq 'DateTime::Span';
        }
        return $values;
    },
);

has has_value => (
    is => 'rwp',
);

has layout => (
    is       => 'rw',
    required => 1,
);

has schema => (
    is       => 'rw',
    required => 1,
);

has vars => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_vars
{   my $self = shift;
    # All possible values that might be needed. Lazy way of working this out:
    # take each possible short name in the whole system, and grep the code to
    # see if it's referred to. This could overmatch, but that is not an issue
    # as more values will be returned than needed
    my %needed = map { $_ => 1 } grep $self->column->code =~ /\Q$_/,
        @{$self->layout->all_short_names};

    # Ensure recurse-prevention information is passed onto curval/autocurs
    # within code values
    my $already_seen = Tree::DAG_Node->new({name => 'root'});
    $self->record->values_by_shortname(
        all_possible_names => \%needed,
        already_seen_code  => $already_seen,
        names              => [$self->column->params],
    );
}

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self,
        has_value => $self->has_value,
        layout    => $self->layout,
        schema    => $self->schema,
        @_,
    );
};

sub html_form
{   my $self = shift;
    @{$self->value} ? $self->value : [''];
}

sub text_all
{   my $self = shift;
    $self->value; # Already array ref
}

sub write_cache
{   my ($self, $table) = @_;

    my @values = sort @{$self->value} if defined $self->value->[0];

    # We are generally already in a transaction at this point, but
    # start another one just in case
    my $guard = $self->schema->txn_scope_guard;

    my $tablec = camelize $table;
    my $vfield = $self->column->value_field;

    # First see if the number of existing values is different to the number to
    # write. If it is, delete and start again
    my $rs = $self->schema->resultset($tablec)->search({
        record_id => $self->record_id,
        layout_id => $self->column->id,
    }, {
        order_by => "me.$vfield",
    });
    $rs->delete if @values != $rs->count;

    my $format = $self->column->dateformat;
    foreach my $value (@values)
    {
        my $row = $rs->next;

        my %to_write;
        if ($self->column->return_type eq 'daterange')
        {
            if ($value)
            {
                my $text = $self->daterange_as_string($value, $format);
                %to_write = (
                    value_date_from => $value->start,
                    value_date_to   => $value->end,
                    value_text      => $text,
                );
            }
        }
        else {
            %to_write = ($vfield => $value);
        }
        if ($row)
        {
            if (!$self->equal($row->$vfield, $value))
            {
                my %blank = %{$self->column->blank_row};
                $row->update({ %blank, %to_write });
            }
        }
        else {
            $self->schema->resultset($tablec)->create({
                record_id => $self->record_id,
                layout_id => $self->column->{id},
                %to_write,
            });
        }
    }
    while (my $row = $rs->next)
    {
        $row->delete;
    }
    $guard->commit;
    return \@values;
}

sub re_evaluate
{   my ($self, %options) = @_;
    return if $options{no_errors} && $self->column->return_type eq 'error';
    my $old = $self->value;
    # If this is a new value, don't re-evaluate, otherwise we'll just get
    # exactly the same value and evaluation can be expensive
    if (!$self->record->new_entry || $options{force})
    {
        $self->clear_init_value;
        $self->clear_value;
        $self->clear_vars;
        $self->clear_already_seen_level;
        $self->clear_already_seen_code;
    }
    my $new = $self->value; # Force new value to be calculated
    $self->changed(1) if !$self->equal($old, $new);
}

sub values
{   $_[0]->value;
}

sub _build_value
{   my $self = shift;

    my $column = $self->column;
    my $code   = $column->code;

    my @values;

    if ($self->init_value)
    {
        my @vs = map {
            ref $_ eq 'HASH' && $self->column->return_type eq 'daterange'
                ? { from => $_->{value_date_from}, to => $_->{value_date_to} }
                : ref $_ eq 'HASH'
                ? $_->{$column->value_field}
                : $_
        } @{$self->init_value};
        @values = map {
            $column->return_type eq 'date'
               ?  $self->_parse_date($_)
               : $column->return_type eq 'daterange'
               ? $self->parse_daterange($_, source => 'db')
               : $_;
        } @vs;
    }
    elsif (!$code)
    {
        # Nothing, $value stays undef
    }
    else {
        # Used during tests to check that $original is being set correctly
        panic "Entering calculation code"
            if $ENV{GADS_PANIC_ON_ENTERING_CODE};

        my $return;
        my $vars = $self->vars;
        try { $return = $column->eval($column->code, $vars) };
        if ($@ || $return->{error})
        {
            my $error = $@ ? $@->wasFatal->message->toString : $return->{error};
            local $Data::Dumper::Indent = 0;
            warning __x"Failed to eval code for field \"{field}\": {error} (code: {code}, params: {params})",
                field => $column->name,
                error => $error, code => $return->{code} || $column->code, params => Dumper($vars);
            $return->{error} = $error;
        }

        @values = $self->convert_value($return); # Convert value as required by calc/rag
    }

    \@values;
}

1;
