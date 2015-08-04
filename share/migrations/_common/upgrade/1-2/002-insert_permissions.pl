#!/usr/bin/perl

use strict;
use warnings;
use DBIx::Class::Migration::RunScript;
 
migrate {
  shift->schema
    ->resultset('Permission')
    ->populate
    ([
        {
            name        => 'create_related',
            description => 'User can create related records and edit fields of existing related records',
            order       => 8,
        },{
            name        => 'link',
            description => 'User can link records between data sets',
            order       => 9,
        },
    ]);
};

