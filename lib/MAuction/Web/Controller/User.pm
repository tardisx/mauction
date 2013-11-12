package MAuction::Web::Controller::User;

use strict;
use warnings;
use DateTime;

use Mojo::Base 'Mojolicious::Controller';

use MAuction::DB::User;
use MAuction::DB::User::Manager;
use MAuction::DB::Session::Manager;

# check if the user is logged in, if not redirect them to the login page.
sub check_user_with_redirect {
    my $self  = shift;
    if (! $self->check_user) {
        return $self->redirect_to($self->url_for('user-login'));
    }

    return 1;
}

# check if this user has either a valid session or has supplied an API key
# in the header
sub check_user {
    my $self  = shift;

    if ($self->check_token || $self->check_session) {
        return 1;
    }

    $self->app->log->error("no token and no user session");
    $self->render( status => 400, json => { error => "no token or session supplied" } );
    return 0;
}

# check the API token
sub check_token {
    my $self = shift;

    my $token = $self->req->headers->header('X-API-Token');
    if (! $token) {
        $self->app->log->debug("no api token");
        return 0;
    }

    $self->app->log->debug("looking for user with token $token");
    my $users = MAuction::DB::User::Manager->get_users(
        query => [ api_token => $token ]
    );
    if (! $users || !@$users) {
        $self->app->log->error("invalid api token");
        return 0;
    }
    $self->stash->{user} = $users->[0];
    return 1;
}

# check the interactive user's session key, if it is valid load the user object
# into the stash
sub check_session {
    my $self = shift;

    my $session_key = $self->session->{key};
    if ($session_key) {
        $self->app->log->debug("checking session key of $session_key");
        my $res = MAuction::DB::Session::Manager->get_sessions( 
            query => [ session => $session_key,
                       session_expiry  => { gt => DateTime->now() }, ]
        );
        if ($res && $res->[0]) {
            $self->app->log->debug("session is good");
            $self->stash->{user} = $res->[0]->user;
            return 1;
        }
    }
    $self->app->log->debug("no valid session");
    return 0;
}

sub login {
    my $self = shift;
    my $username = $self->param('username');
    my $password = $self->param('password');

    utf8::encode($username) if ($username);
    utf8::encode($password) if ($password);

    if ($self->req->method =~ /post/i && $username && $password) {
        $self->app->log->info("attempting login for $username");
        if ($self->stash->{authen}->authenticate($username, $password)) {
            $self->app->log->info("login successful for $username");
            my $user = MAuction::DB::User->new(username   => $username,
                                               last_login => DateTime->now());
            $user->insert_or_update;

            $self->session(key => $user->create_new_session->session);
            $self->redirect_to($self->url_for('home'));
        }
        else {
            $self->app->log->info("failed authentication");
            $self->stash->{message} = 'login failed';
        }
    }
  
    $self->render();
  

}

1;

