use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Exception;

use MAuction::DB::User;
use MAuction::DB::Item;
use MAuction::DB::Bid;
use MAuction::DB::ItemsWinner;

my $t = Test::Mojo->new('MAuction');

# try a rest request with no token
$t->get_ok('/rest/v1/items')
  ->status_is(400)
  ->json_is('/error', 'invalid api token');

my $user = MAuction::DB::User->new(username => "test_$$")->save();
ok ($user, 'user exists');
like ($user->id, qr/^\d+$/, 'user has an id');

$user->generate_new_api_token();
$user->save();

like($user->api_token, qr/^[a-z0-9]{32}$/i, 'looks like a valid token');

$t->ua->on(start => sub {
               my ($ua, $tx) = @_;
               $tx->req->headers->header('X-API-Token' =>  $user->api_token);
           });

$t->post_ok('/rest/v1/items', json => {  })
  ->status_is(400)
  ->json_is('/error', "no value provided for required field 'name'");

$t->post_ok('/rest/v1/items', json => { name => 'mahogany cabinet' })
  ->status_is(400)
  ->json_is('/error', "no value provided for required field 'description'");

$t->post_ok('/rest/v1/items', json => { name => 'mahogany cabinet', description => 'amazing quality' })
  ->status_is(400)
  ->json_is('/error', "no value provided for required field 'bid_increment'");

$t->post_ok('/rest/v1/items', json => { name => 'mahogany cabinet', description => 'amazing quality', bid_increment => 'twelve' })
  ->status_is(400)
  ->json_is('/error', "invalid value for numeric field");

$t->post_ok('/rest/v1/items', json => { name => 'mahogany cabinet', description => 'amazing quality', bid_increment => 5.50 })
  ->status_is(400)
  ->json_is('/error', "no value provided for required field 'bid_min'");

$t->post_ok('/rest/v1/items', json => { name => 'mahogany cabinet', description => 'amazing quality', bid_increment => 5.50, bid_min => 100 })
  ->status_is(400)
  ->json_is('/error', "no value provided for required field 'start_ts'");

$t->post_ok('/rest/v1/items', json => { name => 'mahogany cabinet', description => 'amazing quality', bid_increment => 5.50, bid_min => 100, start_ts => 'who knows' })
  ->status_is(400)
  ->json_is('/error', "an invalid timestamp was provided for the field 'start_ts'");

$t->post_ok('/rest/v1/items', json => { name => 'mahogany cabinet', description => 'amazing quality', bid_increment => 5.50, bid_min => 100, start_ts => '2013-01-11', end_ts => 'whenever' })
  ->status_is(400)
  ->json_is('/error', "an invalid timestamp was provided for the field 'end_ts'");

$t->post_ok('/rest/v1/items', json => { name => 'mahogany cabinet', description => 'amazing quality', bid_increment => 5.50, bid_min => 100, start_ts => '2013-01-11', end_ts => '2014-02-03' })
  ->status_is(200)
  ->json_hasnt('/error')
  ->json_has('/id');

my $id = $t->tx->res->json->{id};

# get
$t->get_ok('/rest/v1/items/'.$id)
  ->status_is(200)
  ->json_is('/id', $id)
  ->json_is('/name', 'mahogany cabinet');

$t->get_ok('/rest/v1/items/1234567890')
  ->status_is(404)
  ->json_hasnt('/id')
  ->json_is('/error', 'no such object id: 1234567890');

# lets delete it
$t->delete_ok('/rest/v1/items/'.$id)
  ->status_is(200)
  ->json_hasnt('/id');

# but not twice
$t->delete_ok('/rest/v1/items/'.$id)
  ->status_is(404)
  ->json_hasnt('/id')
  ->json_is('/error', 'no such object id: '.$id);



done_testing();
