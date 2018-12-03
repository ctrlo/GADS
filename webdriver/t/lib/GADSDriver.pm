package GADSDriver;

use v5.24.0;
use Moo;

use WebDriver::Tiny ();

has home => (
    is => 'ro',
    default => \&_default_home,
);

has username => (
    is => 'ro',
    default => \&_default_username,
);

has password => (
    is => 'ro',
    default => \&_default_password,
);

has webdriver => (
    is => 'ro',
    default => sub { WebDriver::Tiny->new( port => 4444 ) },
);

sub _default_home {
    my $home = $ENV{GADS_HOME} // 'http://localhost:3000';
    $home =~ s{ (?<= / > $ ) }{}x;
    return $home;
}

sub _default_username {
    return $ENV{GADS_USERNAME} // die "Missing GADS_USERNAME";
}

sub _default_password {
    return $ENV{GADS_PASSWORD} // die "Missing GADS_PASSWORD";
}

sub type_into_field {
    my ( $self, $selector, $value ) = @_;
    my $webdriver = $self->webdriver;

    my $field_el = $webdriver->find( $selector, dies => 0 );
    if ( 0 == $field_el->size ) {
        return undef;
    }
    else {
        $field_el->send_keys( $value );
        return $self;
    }
}

sub go_to_url {
    my ( $self, $url ) = @_;

    return $self->webdriver->get( $self->home . $url );
}

1;
