use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Exception;

use lib 't/lib';

use MAuction::DB::User;
use Test::MAuction::Authenticator;

# test user logins, sessions etc
my $t = Test::Mojo->new('MAuction');


# modify our authenticator
my $authen = Test::MAuction::Authenticator->new();
$t->app->hook(before_routes => sub {
    my $c = shift;
    $c->stash->{authen} = $authen;
});

# try to get to the homepage - we should be redirected to login
$t->get_ok('/')
  ->status_is(302);

$t->get_ok('/user/login')
  ->status_is(200);

$t->post_ok('/user/login', form => { username => 'foo', password => 'bar' })
  ->status_is(200)
  ->content_like(qr/login failed/i);

# good login
$t->post_ok('/user/login', form => { username => "good_$$", password => "good_$$" })
  ->status_is(302)
  ->content_unlike(qr/login failed/i);

# this user should exist now
my $res = MAuction::DB::User::Manager->get_users(query => [ username => "good_$$" ] );
ok($res && $res->[0] && $res->[0]->username eq "good_$$", 'user created');

# and have a session key
my $user = $res->[0];
ok($user->sessions->[0]->session, 'has a session key');

# and we don't get redirected when we hit the front page now
$t->get_ok('/')
  ->status_is(200);

done_testing();
