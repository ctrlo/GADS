package GADS::Chronology;

use Moo;

use MooX::Types::MooseLike::Base qw(ArrayRef Int);

use Log::Report 'linkspace';

use JSON qw(encode_json);

has id => (
    is       => 'ro',
    required => 1,
    isa      => Int,
    trigger  => sub {
        shift->_clear_current;
    },
);

has _current => (
    is      => 'lazy',
    clearer => 1,
);

sub _build__current {
    my $self = shift;
    my $id   = $self->id
      or error __"No ID provided";
    my $current = $self->schema->resultset('Current')->find($id)
      or error __"Current record ID not found";
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

sub as_json {
    my ( $self, %options ) = shift;

    my $page = $options{page} || 1;

    my $current = $self->_current
      or error __x"No current record found for ID {id}", id => $self->id;

    my @result;
    my @records = map { $_->{id} } $current->records->search(
        {},
        {
            columns      => [qw/me.id/],
            order_by     => { -desc => 'me.created' },
            page         => $page,
            rows         => 10,
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    )->all;

    my $old;

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
            if ( $col->{readonly} ) {
                $chronology_definition->{action}->{datetime} = $col->{data}->{value}
                  if $col->{name} eq 'Last edited time';
                $chronology_definition->{action}->{user} = $col->{data}->{value}
                  if $col->{name} eq 'Last edited by';
                next;
            }
            my $name = $col->{name};
            if ( $col->{type} =~ /^curval$/i ) {
                my $links = $col->{data}->{links};
                for my $link (@$links) {
                    for my $l ( @{ $link->{presentation}->{columns} } ) {
                        $out->{$name}->{ $l->{name} } = $l->{data}->{value};
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
        $chronology_definition->{data}           = $new_values;
        $chronology_definition->{action}->{type} = $old ? 'update' : 'create';
        $chronology_definition->{page}           = $page;
        push @result, $chronology_definition;
        $old = $out;
    }

    encode_json \@result;
}

sub _strip {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH';
    for my $key ( keys %$data ) {
        $self->_strip( $data->{$key} ) if ref $data->{$key} eq 'HASH';
        delete $data->{$key}
          unless $data->{$key} || ( ref $data->{$key} eq 'HASH' && scalar keys %{ $data->{$key} } );
    }
}

sub _compare {
    my ( $self, $a, $b ) = @_;
    my $diff = {};
    my %seen;
    error __"Input and output are of differing types"
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
