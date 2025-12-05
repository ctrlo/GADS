package GADS::Hooks;

use Log::Report 'linkspace';
use Moo;

with 'MooX::Singleton';

my $available_hooks = {
    'record.write.before_write_values' => 1,
};

has _hooks => (
    is      => 'ro',
    default => sub { +{} },
);

sub hook_exists
{   my ($self, $name) = @_;
    !! $available_hooks->{$name};
}

sub add_hook
{   my ($self, $name, $code) = @_;
    $self->hook_exists($name)
        or panic __x"Hook {name} not known", name => $name;
    $self->_hooks->{$name}
        and panic __x"Hook {name} already exists", name => $name;
    $self->_hooks->{$name} = $code;
}

sub run_hook
{   my ($self, $name) = (shift, shift);
    $self->hook_exists($name)
        or panic __x"Hook {name} not known", name => $name;
    my $hook = $self->_hooks->{$name}
        or return;
    $hook->(@_);
}

1;
