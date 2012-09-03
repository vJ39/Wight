use strict;
use warnings;
use Test::More;

use Test::Wight;
use Plack::Request;
use Plack::Middleware::Session;
use Plack::Session;
use LWP::Simple qw($ua);

# XXX HTTP::Cookies adds '.local' to 'localhost' domain
# So access to localhost by '127.0.0.1'

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $session = Plack::Session->new($env);
    my $res = $req->new_response(200);
    $res->content($session->id);
    return $res->finalize;
};
$app = Plack::Middleware::Session->new->wrap($app);

my $wight = Test::Wight->new;
$wight->cookie_jar; # build; FIXME ugly

my $port = $wight->spawn_psgi($app);

$wight->handshake;

$wight->visit("http://127.0.0.1:$port/");
my $session_id = $wight->evaluate('document.body.textContent');

$wight->visit("http://127.0.0.1:$port/");
is $wight->evaluate('document.body.textContent'), $session_id;

$ua->cookie_jar($wight->reload_cookie_jar);

my $res = $ua->get("http://127.0.0.1:$port/");
is $res->content, $session_id, 'session inherited';

done_testing;
