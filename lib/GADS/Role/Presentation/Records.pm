package GADS::Role::Presentation::Records;

use Moo::Role;

sub presentation {
    my $self = shift;

    return [
        map $_->presentation(group => $self->is_group), @{$self->results}
    ];
}

sub aggregate_presentation
{   my $self = shift;

    my $record = $self->aggregate_results
        or return undef;

    my @presentation = map {
        $record->fields->{$_->id} && $_->presentation(datum_presentation => $record->fields->{$_->id}->presentation)
    } @{$self->columns_view};

    return +{
        columns => \@presentation,
    };
}

1;
