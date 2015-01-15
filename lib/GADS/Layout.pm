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

package GADS::Layout;

use Algorithm::Dependency::Ordered;
use Algorithm::Dependency::Source::HoA;
use GADS::Column;
use GADS::Column::Calc;
use GADS::Column::Date;
use GADS::Column::Daterange;
use GADS::Column::Enum;
use GADS::Column::File;
use GADS::Column::Intgr;
use GADS::Column::Person;
use GADS::Column::Rag;
use GADS::Column::String;
use GADS::Column::Tree;
use Log::Report;
use String::CamelCase qw(camelize);

use Moo;

has schema => (
    is       => 'rw',
    required => 1,
);

has user => (
    is       => 'rw',
    required => 1,
);

has columns => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_columns',
);

# Instantiate new class. This builds a list of all
# columns, so that it's cached for any later function
sub _build_columns
{   my $self = shift;

    my $cols_rs = $self->schema->resultset('Layout')->search({},{
        order_by => ['me.position', 'enumvals.id'],
        join     => 'enumvals',
        prefetch => ['calcs', 'rags' ],
    });

    $cols_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');

    my @allcols = $cols_rs->all;

    my @return;
    foreach my $col (@allcols)
    {
        my $class = "GADS::Column::".camelize $col->{type};
        my $column = $class->new(set_values => $col, schema => $self->schema);
        push @return, $column;
    }

    # XXX Probably a more efficient algorithm for this
    # Now that we have all columns built, we need to tag on dependent cols
    foreach my $col (@return)
    {
        unless ($col->userinput)
        {
            # Check a calculated value exists for this field
            next if $col->type eq "calc" && !$col->calc;
            next if $col->type eq "rag" && !($col->green || $col->amber || $col->red);

            my @depends_on;
            foreach (@return)
            {
                my $name  = $_->name; my $suffix = $_->suffix;
                my $regex = qr/\Q[$name\E$suffix\Q]/i;

                if ($col->type eq "calc")
                {
                    next unless $col->calc =~ $regex;
                }
                elsif ($col->type eq "rag") {
                    next unless $col->green =~ $regex || $col->amber =~ $regex || $col->red =~ $regex;
                }
                else {
                    die "I don't know what to do with a none-user input field of ".$col->type;
                }
                push @depends_on, $_->id;
            }
            $col->depends_on(\@depends_on);
        }

        # And also any columns that are children (in the layout)
        my @depends = grep {$_->display_field && $_->display_field == $col->id} @return;
        my @depended_by = map { { id => $_->id, regex => $_->display_regex } } @depends;
        $col->depended_by(\@depended_by);
    }


    my %columns = map { $_->{id} => $_ } @return; # Allow easier retrieval
    \%columns;
}

sub all
{   my ($self, %options) = @_;

    my $type = $options{type};

    my $include_hidden = $options{include_hidden} || $self->user->{permission}->{layout} ? 1 : 0;

    my @columns = sort {($a->position||0) <=> ($b->position||0)} values %{$self->columns};
    @columns = $self->_order_dependencies(@columns) if $options{order_dependencies};
    @columns = grep { $_->type eq $type } @columns if $type;
    @columns = grep { $_->remember == $options{remember} } @columns if defined $options{remember};
    @columns = grep { !$_->hidden } @columns unless $include_hidden;
    @columns = grep { $_->userinput == $options{userinput} } @columns if defined $options{userinput};
    @columns;
}

# Order the columns in the order that the calculated values depend
# on other columns
sub _order_dependencies
{   my ($self, @columns) = @_;

    my %deps = map {
        $_->id => ($_->depends_on || []);
    } @columns;

    my $source = Algorithm::Dependency::Source::HoA->new(\%deps);
    my $dep = Algorithm::Dependency::Ordered->new(source => $source)
        or die 'Failed to set up dependency algorithm';
    my @order = @{$dep->schedule_all};
    map { $self->columns->{$_} } @order;
}

sub position
{   my ($self, $params) = @_;
    foreach my $o (keys %$params)
    {
        next unless $o =~ /position([0-9]+)/;
        $self->schema->resultset('Layout')->find($1)->update({ position => $params->{$o} });
    }
}

sub column
{   my ($self, $id) = @_;
    $self->columns->{$id};
}

sub view
{   my ($self, $view_id, %options) = @_;

    return unless $view_id;
    my $view    = GADS::View->new(
        user   => $self->{user},
        id     => $view_id,
        schema => $self->schema,
        layout => $self,
    );
    my %view_layouts = map { $_ => 1 } @{$view->columns};
    grep { $view_layouts{$_->{id}} } $self->all(%options);
}

1;

