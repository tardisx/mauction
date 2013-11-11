use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Exception;

use MAuction::DB::User;
use MAuction::DB::Item;
use MAuction::DB::Bid;
use MAuction::DB::ItemsWinner;

my $t = Test::Mojo->new('MAuction');

my $ouser = MAuction::DB::User->new(username => "test_$$", last_login => DateTime->now())->save();
ok ($ouser, 'user exists');
like ($ouser->id, qr/^\d+$/, 'user has an id');

my $pid = $$;
my $busers = {};
foreach my $username (qw/buser1 buser2 buser3/) {
  my $auser = MAuction::DB::User->new(username => "${username}_${pid}", last_login => DateTime->now())->save();
  $busers->{$username} = $auser;
}

my $item = MAuction::DB::Item->new(user_id => $ouser->id,
                                   start_ts => DateTime->now(),
                                   end_ts   => DateTime->now()->add(days => 1),
                                   name     => "test $$ item",
                                   description => "test $$ description",
                                   bid_increment => 2.50,
                                   bid_min  => 10.00,
                                  )->save();
my @bids;

push @bids, { name => "user3: too cheap to start",
              user => $busers->{buser3}, amount => 1.99, win_user => undef, win_amount => undef, exception => qr/at least the minimum bid amount/};
push @bids, { name => "user1: first good bid",
              user => $busers->{buser1}, amount => 15, win_user => $busers->{buser1}, win_amount => 10 };
push @bids, { name => "user2: failed to outbid max, increases proxy of user1",
              user => $busers->{buser2}, amount => 13, win_user => $busers->{buser1}, win_amount => 15.50 };
push @bids, { name => "user2: outbids with 30, winning now at 17.50",
              user => $busers->{buser2}, amount => 30, win_user => $busers->{buser2}, win_amount => 17.50 };
push @bids, { name => "user1: can't outbid with 20",
              user => $busers->{buser1}, amount => 20, win_user => $busers->{buser2}, win_amount => 22.50 };
push @bids, { name => "user1: goes for broke at 100 proxy win to 32.50",
              user => $busers->{buser1}, amount => 100, win_user => $busers->{buser1}, win_amount => 32.50 };
push @bids, { name => "user3: tries to be cheeky",
              user => $busers->{buser3}, amount => 10,  win_user => $busers->{buser1}, win_amount => 32.50, exception => qr/does not exceed/ };
push @bids, { name => "user1: tries to reduce the potential for pain", # but can't
              user => $busers->{buser1}, amount => 50, win_user => $busers->{buser1}, win_amount => 32.50, exception => qr/you cannot bid lower than your previous bids/ };

my %bid_options = ( 'item_id' => $item->id );

foreach my $abid (@bids) {
  if ($abid->{exception}) {
    throws_ok { MAuction::DB::Bid->new(%bid_options, user_id => $abid->{user}->id, amount => $abid->{amount})->save() }
              $abid->{exception}, $abid->{name} . ' - bid rejected correctly';
  }
  else {
    lives_ok { MAuction::DB::Bid->new(%bid_options, user_id => $abid->{user}->id, amount => $abid->{amount})->save() }
             $abid->{name} . ' - bid inserted';
  }

  my $winner_row = MAuction::DB::ItemsWinner->new(id => $item->id)->load();
  my $winner =  $winner_row->current_winner_for_item;

  $winner =~ s/[\(\)]//g if $winner;
  my ($win_user, $win_amount) = split /,/, ($winner || '');
  $win_amount += 0 if ($win_amount);

  is ($win_user,  $abid->{win_user} ? $abid->{win_user}->id : undef, $abid->{name} . ' - correct winning user');
  is ($win_amount, $abid->{win_amount}, $abid->{name} . ' - correct winning amount');
}


done_testing();
