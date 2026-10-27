use strict;
use warnings;

use DBIx::Class::Migration::RunScript;

use Dancer2;
use JSON::MaybeXS qw(decode_json encode_json);

use FindBin;
use lib "$FindBin::Bin/../lib";

migrate {
    my $runner = shift;
    my $schema = $runner->schema;
    
    GADS::Config->instance( config => config );
    my $guard = $schema->txn_scope_guard;

    foreach my $fileoption ($schema->resultset('FileOption')->all) {
        my $layout = $schema->resultset('Layout')->find($fileoption->layout_id);
        next unless $layout && $fileoption->filesize;

        my $options_hash = $layout->options ? decode_json($layout->options) : {};
        $options_hash->{filesize} = $fileoption->filesize;

        $layout->update({
            options => encode_json($options_hash),
        });
    }

    $guard->commit;
}
