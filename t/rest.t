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
  ->json_is('/name', 'mahogany cabinet')
  ->json_has('/current_winner_for_item');

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

# collection
# create some items to be in the collection
my $ids = {};
foreach (1..10) {
  $t->post_ok('/rest/v1/items', json => { name => 'collection item', description => 'xx', bid_increment => 5.50, bid_min => 100, start_ts => '2013-01-11', end_ts => '2014-02-03' })
    ->status_is(200)
    ->json_hasnt('/error')
    ->json_has('/id');
  $ids->{$t->tx->res->json->{id}}++;
}
is(keys %$ids, 10, '10 items created');

$t->get_ok('/rest/v1/items?sort=id%20DESC')
  ->status_is(200);

# Check we receive them back in the order we created them.
# This is a little fragile - if something else modified the database
# at the same time (like doing simultaneous tests) this might fail.
my $idx = 0;
foreach (reverse sort keys %$ids) {
  $t->json_is("/$idx/id", $_);
  $idx++;
}

# Do any collection fetch, limited to only 5 items, make sure we get back 5
$t->get_ok('/rest/v1/items?limit=5')
  ->status_is(200);

is(scalar @{ $t->tx->res->json}, 5, '5 items');



done_testing();
