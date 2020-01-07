use Test::More;
use strict;
use warnings;

# Run in a BEGIN block to run before "use GADS;"
BEGIN {
    if ( ! -f 'config.yml' ) {
        plan skip_all => 'No application configuration in config.yml';
    }
    else {
        plan tests => 9;
    }
}

use GADS;
use Plack::Test;
use HTTP::Request::Common;
use DBICx::Sugar qw(schema);

my $app = GADS->to_app;

my $site = schema->resultset('Site')->next
    or die "no site loaded";

my $host = $site->host;

ok defined $host, "configured site '$host'";
my @header = (Host => $host);

ok defined $app, 'Created app';
isa_ok $app, 'CODE';

my $client = Plack::Test->create($app);
ok defined $client, 'Created response handlers';

my $resp1  = $client->request(GET '/', @header);
ok defined $resp1, 'a route handler is defined for /';
cmp_ok $resp1->code, '==', 302, 'Redirect';

my $resp2  = $client->request(GET '/login?return_url', @header);
ok defined $resp2, 'getting a page';
ok $resp2->is_success;
cmp_ok $resp2->code, '==', 200, 'OK';

done_testing;
