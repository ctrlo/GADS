
=pod
GADS - Globally Accessible Data Store
Copyright (C) 2017 Ctrl O Ltd

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

package GADS::DBIC;

use base qw(DBIx::Class);

# Used as a component for result sources to perform additional DBIC functions
# (such as validation of values).  For validation, the Result needs a
# validate() function.  It should raise an exception if there is a problem.

sub insert
{   my $self = shift;
    $self->_validate(@_);
    $self->_before_create(@_);
    my $guard  = $self->result_source->schema->txn_scope_guard;
    my $return = $self->next::method(@_);
    $self->after_create
        if $self->can('after_create');
    $guard->commit;
    $return;
}

sub delete
{   my $self = shift;
    $self->before_delete
        if $self->can('before_delete');
    $self->next::method(@_);
}

sub update
{   my $self = shift;
    $self->_validate(@_);
    $self->next::method(@_);
}

sub _validate
{   my ($self, $values) = @_;

    # If update() has been called with a set of values, then these need to be
    # updated in the object first, otherwise validation will be done on the
    # existing values in the object not the new ones.
    if ($values)
    {
        $self->$_($values->{$_}) foreach keys %$values;
    }
    $self->validate
        if $self->can('validate');
}

sub _before_create
{   my $self = shift;
    $self->before_create
        if $self->can('before_create');
}

1;
