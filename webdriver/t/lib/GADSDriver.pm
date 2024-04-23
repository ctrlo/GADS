package GADSDriver;

use v5.24.0;
use Moo;

use WebDriver::Tiny ();

=head1 NAME

GADSDriver - GADS-specific wrapper for WebDriver::Tiny

=head1 SYNOPSIS

    use GADSDriver ();
    my $gads = GADSDriver->new(...);
    ...;
    my $webdriver = $gads->webdriver;

=head1 METHODS

=head2 new

A standard L<< Moo >> constructor which takes the following attributes,
all of which also provide read-only accessor methods:

=head3 home

The URL of the applications home page.  Defaults to the C<< GADS_HOME >>
environment variable.

=cut

has home => (
    is => 'ro',
    default => \&_default_home,
);

sub _default_home {
    my $home = $ENV{GADS_HOME} // 'http://localhost:3000';
    $home =~ s{ (?<= / > $ ) }{}x;
    return $home;
}

=head3 username

The username of an existing account to log in to GADS with.  Defaults to
the C<< GADS_USERNAME >> environment variable.

=cut

has username => (
    is => 'ro',
    default => \&_default_username,
);

sub _default_username {
    return $ENV{GADS_USERNAME} // die "Missing GADS_USERNAME";
}

=head3 password

The password for the existing GADS account.  Defaults to the C<<
GADS_PASSWORD >> environment variable.

=cut

has password => (
    is => 'ro',
    default => \&_default_password,
);

sub _default_password {
    return $ENV{GADS_PASSWORD} // die "Missing GADS_PASSWORD";
}

=head3 webdriver

An object which supports the interface used by L<< WebDriver::Tiny >>.
Defaults to using an object of that class that connects to port 4444.

=cut

has webdriver => (
    is => 'ro',
    default => sub {
        WebDriver::Tiny->new(
            port => 4444,
            capabilities => {
                'goog:chromeOptions' => { args => ['--headless'] },
            },
        );
    },
);

=head2 type_into_field

Find an element specified by a CSS selector contained in the first
argument, and enter a value specified by the second argument into that
field.

=cut

sub type_into_field {
    my ( $self, $selector, $value ) = @_;
    my $webdriver = $self->webdriver;

    my $field_el = $webdriver->find( $selector, dies => 0, tries => 20 );
    if ( 0 == $field_el->size ) {
        return undef;
    }
    else {
        $field_el->send_keys( $value );
        return $self;
    }
}

=head2 go_to_url

Takes one argument, a URL to load relative to the application's root URL.

=cut

sub go_to_url {
    my ( $self, $url ) = @_;

    return $self->webdriver->get( $self->home . $url );
}

1;
__END__

=head1 SEE ALSO

L<< Test::GADSDriver >>

=cut
