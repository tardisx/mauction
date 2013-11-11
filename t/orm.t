use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Exception;

use MAuction::DB::User;
use MAuction::DB::Item;
use MAuction::DB::Bid;

my $t = Test::Mojo->new('MAuction');

my $user = MAuction::DB::User->new(username => "test_$$", last_login => DateTime->now())->save();
ok ($user, 'user exists');
like ($user->id, qr/^\d+$/, 'user has an id');

my $buser = MAuction::DB::User->new(username => "test2_$$", last_login => DateTime->now())->save();
ok ($buser, 'user2 exists');
like ($buser->id, qr/^\d+$/, 'user2 has an id');

my $item = MAuction::DB::Item->new(user_id => $user->id,
                                   start_ts => DateTime->now(),
                                   end_ts   => DateTime->now()->add(days => 1),
                                   name     => "test $$ item",
                                   description => "test $$ description",
                                   bid_increment => 2.50,
                                   bid_min  => 10.00,
                                  )->save();

my %bid_options = ( 'item_id' => $item->id, user_id => $buser->id );

throws_ok { MAuction::DB::Bid->new(%bid_options, amount => 1)->save } qr/bid is not at least the minimum bid amount/, 'too small bid ok';
lives_ok  { MAuction::DB::Bid->new(%bid_options, amount => 10)->save } 'bid at minimum ok';
throws_ok { MAuction::DB::Bid->new(%bid_options, amount => 12)->save } qr/bid of 12.00 does not exceed winning bid of 10.00 by at least 2.50/, 'second bid not high enough';
lives_ok  { MAuction::DB::Bid->new(%bid_options, amount => 12.50)->save } 'second big high enough';


done_testing();
