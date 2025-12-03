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

package GADS::Email;

use GADS::Config;
use Log::Report 'linkspace';
use Mail::Message;
use Mail::Message::Body::String;
use Mail::Transport::Sendmail;
use Text::Autoformat qw(autoformat break_wrap);

use Moo;

with 'MooX::Singleton';

has message_prefix => (
    is => 'lazy',
);

sub _build_message_prefix
{   my $self = shift;
    my $prefix = $self->config->gads->{message_prefix} || "";
    $prefix .= "\n" if $prefix;
    $prefix;
}

has config => (
    is => 'lazy',
);

sub _build_config
{   my $self = shift;
    GADS::Config->instance;
}

has email_from => (
    is => 'lazy',
);

sub _build_email_from
{   my $self = shift;
    $self->config->gads->{email_from};
}

sub send
{   my ($self, $args) = @_;

    my $emails   = $args->{emails} or error __"Please specify some recipients to send an email to";
    my $subject  = $args->{subject} or error __"Please enter a subject for the email";
    my $reply_to = $args->{reply_to};

    my @parts;

    push @parts, Mail::Message::Body::String->new(
        mime_type   => 'text/plain',
        disposition => 'inline',
        data        => autoformat($args->{text}, {all => 1, break=>break_wrap}),
    ) if $args->{text};

    push @parts, Mail::Message::Body::String->new(
        mime_type   => 'text/html',
        disposition => 'inline',
        data        => $args->{html},
    ) if $args->{html};

    @parts or panic "No plain or HTML email text supplied";

    my $content_type = @parts > 1 ? 'multipart/alternative' : $parts[0]->type;

    my $msg = Mail::Message->build(
        Subject                    => $subject,
        From                       => $self->email_from,
        'Content-Type'             => $content_type,
        'X-Auto-Response-Suppress' => 'All',
        attach                     => \@parts,
    );
    $msg->head->add('Reply-to' => $reply_to) if $reply_to;

    # Start a mailer
    my $mailer = Mail::Transport::Sendmail->new(
        sendmail_options => [-f => $self->email_from],
    );

    my %done;
    foreach my $email (@$emails)
    {
        next if $done{$email}; # Stop duplicate emails
        $done{$email} = 1;
        $msg->head->set(to => $email);
        $mailer->send($msg);
    }
}

sub message
{   my ($self, $args, $user) = @_;

    my @emails;

    if ($args->{records} && $args->{col_id})
    {
        foreach my $record (@{$args->{records}->results})
        {
            my $email = $record->fields->{$args->{col_id}}->email;
            push @emails, $email if $email;
        }
    }

    push @emails, @{$args->{emails}} if $args->{emails};

    @emails or return;

    (my $text = $args->{text}) =~ s/\s+$//;
    $text = $self->message_prefix.$text
             ."\n\nMessage sent by: ".($user->value||"")." (".$user->email.")\n";

    my $email = {
        subject  => $args->{subject},
        emails   => \@emails,
        text     => $text,
        reply_to => $user->email,
    };
    $self->send($email);
}

1;

