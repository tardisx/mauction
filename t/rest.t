use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Exception;

use MAuction::DB::User;
use MAuction::DB::Item;
use MAuction::DB::Bid;
use MAuction::DB::ItemsWinner;

my $t = Test::Mojo->new('MAuction');

my $user = MAuction::DB::User->new(username => "test_$$")->save();
ok ($user, 'user exists');
like ($user->id, qr/^\d+$/, 'user has an id');

$user->generate_new_api_token();
$user->save();

like($user->api_token, qr/^[a-z0-9]{32}$/i, 'looks like a valid token');


done_testing();
