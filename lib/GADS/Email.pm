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

use Log::Report;
use Text::Autoformat qw(autoformat break_wrap);

use Dancer2 ':script';
use Dancer2::Plugin::Emailesque;
use Dancer2::Plugin::DBIC qw(schema resultset rset);

sub send($)
{   my ($class, $args) = @_;

    my $emails   = $args->{emails} or error __"Please specify some recipients to send an email to";
    my $subject  = $args->{subject} or error __"Please enter some text for the email";
    my $reply_to = $args->{reply_to};
    my $message = autoformat $args->{text}, {all => 1, break=>break_wrap};

    my $params = {
        subject  => $subject,
        message  => $message,
    };
    $params->{headers} = {
        "Reply-to" => $reply_to, # Reply_to in Emailesque is broken
    } if $reply_to;
    my %done;
    foreach my $email (@$emails)
    {
        next if $done{$email}; # Stop duplicate emails
        $done{$email} = 1;
        $params->{to} = $email;
        email $params;
    }
}

sub message
{
    my ($self, $params, $records, $ids, $user) = @_;

    my @emails;
    my $field = $params->{peopcol}; # The people field to use
    foreach my $record (@$records)
    {
        push @emails, $record->$field->value->email
            if grep {$_ == $record->id} @$ids;
    }

    $params->{text} =~ s/\s+$//;
    my $text = config->{gads}->{message_prefix}
             ."\n". $params->{text}
             ."\n\nMessage sent by: $user->{value} ($user->{email})\n";

    my $email = {
        subject  => $params->{subject},
        emails   => \@emails,
        text     => $text,
        reply_to => $user->{email},
    };
    $self->send($email);
}

1;

