package GADS::Chronology;

use Moo;

use MooX::Types::MooseLike::Base qw(ArrayRef Int);

use Log::Report 'linkspace';

use JSON qw(to_json);

use feature qw/say/;

use Data::Dump qw(pp);

has id => (
    is       => 'ro',
    required => 1,
    isa      => Int,
    trigger  => sub {
        my $self = shift;
        $self->_clear_current; # Probably not needed, but ensures we clear the current record when ID changes
        $self->_clear_last_record; # As above for the last record
    },
);

has _current => (
    is      => 'lazy',
    clearer => 1,
);

sub _build__current {
    my $self = shift;
    my $id   = $self->id
      or error __ "No ID provided";
    my $current = $self->schema->resultset('Current')->find($id)
      or error __ "Current record ID not found";
    return $current;
}

has schema => (
    is       => 'ro',
    required => 1,
);

has user => (
    is       => 'ro',
    required => 1,
);

has _last_record => (
    is      => 'rwp',
    clearer => 1,
);

sub as_json {
    my ( $self, %options ) = @_;

    my $page = $options{page} // 1;

    my $current = $self->_current
      or error __x "No current record found for ID {id}", id => $self->id;

    my @result;
    my $rs = $current->records->search(
        {},
        {
            columns      => [qw/me.id/],
            order_by     => { -asc => 'me.created' },
            page         => $page,
            rows         => 10,
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    );

    my $last_page = $rs->pager->last_page;

    return if $last_page < $page;

    my @records = map { $_->{id} } $rs->all;

    my $old = $self->_last_record;

    for my $record (@records) {
        my $out                   = +{};
        my $chronology_definition = +{};
        my $record_object         = GADS::Record->new(
            user   => $self->user,
            schema => $self->schema,
        );
        my $r = $record_object->find_record_id($record);
        next unless $r;
        my $r_presentation = $r->presentation;
        for my $col ( @{ $r_presentation->{columns} } ) {
            if ( $col->{name} =~ /^last edited/i ) {
                $chronology_definition->{action}->{datetime} = $col->{data}->{value}
                    if $col->{name} eq 'Last edited time';
                if ($col->{name} eq 'Last edited by') {
                    for my $detail ( @{ $col->{data}->{details} } ) {
                        for my $k ( keys %$detail ) {
                            $chronology_definition->{action}->{user}->{$k} = $detail->{$k};
                        }
                        $chronology_definition->{action}->{user}->{type} = 'person';
                    }
                }
                next;
            }
            my $name = $col->{name};
            if ( $col->{type} eq 'person' ) {
                for my $detail ( @{ $col->{data}->{details} } ) {
                    for my $k ( keys %$detail ) {
                        $out->{$name}->{$k} = $detail->{$k};
                    }
                    $out->{$name}->{type} = 'person';
                }
                next;
            }
            if ( $col->{type} =~ /^curval$/i ) {
                my $links = $col->{data}->{links};
                for my $link (@$links) {
                    for my $l ( @{ $link->{presentation}->{columns} } ) {
                        $out->{$name}->{ $l->{name} } = $l->{data}->{value} unless $l->{type} eq 'person';
                        if ( $l->{type} eq 'person' ) {
                            for my $detail ( @{ $l->{data}->{details} } ) {
                                for my $k ( keys %$detail ) {
                                    $out->{$name}->{ $l->{name} }->{$k} = $detail->{$k};
                                }
                            }
                        }
                    }
                }
            }
            else {
                my $value = $col->{data}->{value};
                $out->{$name} = $value;
            }
        }
        $self->_strip($out);
        my $new_values = $old ? $self->_compare( $old, $out ) : $out;
        $chronology_definition->{data} = $new_values;
        $chronology_definition->{action}->{type} = $old ? 'update' : 'create';
        push @result, $chronology_definition;
        $old = $out;
    }

    $self->_set__last_record($old);

    my $json_result = +{
        'page'      => $page,
        'last_page' => $last_page,
        'result'    => \@result,
    };

    to_json( $json_result );
}

sub _strip {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH';
    for my $key ( keys %$data ) {
        $self->_strip( $data->{$key} ) if ref $data->{$key} eq 'HASH';
        delete $data->{$key}
          unless $data->{$key}
          || ( ref $data->{$key} eq 'HASH' && scalar keys %{ $data->{$key} } );
    }
}

sub _compare {
    my ( $self, $a, $b ) = @_;
    my $diff = {};
    my %seen;
    error __ "Input and output are of differing types"
      unless ref $a eq 'HASH' && ref $b eq 'HASH';
    for my $key ( keys %$a ) {
        next if $seen{$key};
        $seen{$key} = 1;
        unless ( exists $b->{$key} ) {
            $diff->{$key} = {
                old => $a->{$key},
                new => undef,
            };
            next;
        }
        if ( ref $a->{$key} eq 'HASH' || ref $b->{$key} eq 'HASH' ) {
            my $sub_diff = $self->_compare( $a->{$key}, $b->{$key} );
            $diff->{$key} = $sub_diff if scalar( keys %$sub_diff );
            next;
        }
        next if $a->{$key} eq $b->{$key};
        $diff->{$key}->{old} = $a->{$key};
        $diff->{$key}->{new} = $b->{$key};
    }
    for my $key ( keys %$b ) {
        next if $seen{$key};
        $seen{$key} = 1;
        unless ( exists $a->{$key} ) {
            $diff->{$key} = {
                old => undef,
                new => $b->{$key},
            };
            next;
        }
        if ( ref $a->{$key} eq 'HASH' || ref $b->{$key} eq 'HASH' ) {
            my $sub_diff = $self->_compare( $a->{$key}, $b->{$key} );
            $diff->{$key} = $sub_diff if scalar( keys %$sub_diff );
            next;
        }
        next if $a->{$key} eq $b->{$key};
        $diff->{$key}->{old} = $a->{$key};
        $diff->{$key}->{new} = $b->{$key};
    }
    return $diff;
}

1;
