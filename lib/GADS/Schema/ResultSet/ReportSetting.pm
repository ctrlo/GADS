package GADS::Schema::ResultSet::ReportSetting;

use strict;
use warnings;
use Moo;

use Log::Report 'linkspace';

extends 'DBIx::Class::ResultSet';

sub BUILDARGS { $_[2] || {} }

#Need to make sure defaults are present before we start using them

sub _init_strings {
    my ($self) = @_;

    print STDOUT "Initialising strings\n";

    $self->save_string( 'security_marking', 'Official Secret' )
      unless ( $self->load_string( 'security_marking', 1 ) );
}

sub load_all_strings {
    my ($self) = @_;

    print STDOUT "Loading strings\n";

    $self->_init_strings;

    my $strings = $self->search( { type => 'string' } );

    my $result = [ map { $self->_map_setting($_) } $strings->all ];

    return $result;
}

sub load_string {
    my ( $self, $name, $init_call ) = @_;

    $self->_init_strings unless $init_call;

    my $string = $self->find( { name => $name, type => 'string' } );

    return $string ? $string->value : undef;
}

sub load_all_data {
    my ($self) = @_;

    my $defaults = $self->search( { type => 'data' } );

    return [ map { $self->_map_setting($_) } $defaults->all ];
}

sub load_data {
    my ( $self, $name ) = @_;

    my $data = $self->find( { name => $name, type => 'data' } );

    return $data ? +{ data => $data->data, type => $data->value } : undef;
}

sub save_string {
    my ( $self, $name, $value ) = @_;

    print STDOUT "Saving string $name\n";

    my $txn_guard = $self->result_source->schema->txn_scope_guard;

    my $string = $self->find_or_create( { name => $name, type => 'string' } );

    $string->update( { value => $value } );

    $txn_guard->commit;

    return $string;
}

sub save_data {
    my ( $self, $name, $data, $type ) = @_;

    my $txn_guard = $self->result_source->schema->txn_scope_guard;

    my $data_item = $self->find_or_create( { name => $name, type => 'data' } );

    $data_item->update( { data => $data, value => $type } );

    $txn_guard->commit;

    return $data;
}

sub delete {
    my ( $self, $name ) = @_;

    my $txn_guard = $self->result_source->schema->txn_scope_guard;

    my $setting = $self->find( { name => $name } );

    $setting->delete if $setting;

    $txn_guard->commit;

    return;
}

sub load_all {
    my ($self) = @_;

    my $all_settings = $self->search( {} );

    my @settings = [ map { $self->_map_setting($_) } $all_settings->all ];

    return \@settings;
}

sub _map_setting {
    my ( $self, $setting ) = @_;

    if ( $setting->type eq 'string' ) {
        return +{
            id    => $setting->id,
            name  => $setting->name,
            value => $setting->value
        };
    }
    elsif ( setting->type eq 'data' ) {
        return +{
            id   => $setting->id,
            name => $setting->name,
            data => $setting->data,
            type => $setting->value
        };
    }
    else {
        error __x( "Unknown setting type %s", $setting->type );
    }

    #Should never get here
    return undef;
}

1;
