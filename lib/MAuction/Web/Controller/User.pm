package MAuction::Web::Controller::User;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';

use MAuction::DB::User::Manager;

sub check_user {
    my $self  = shift;

    if ($self->check_token || $self->check_session) {
        return 1;
    }

    $self->app->log->error("no token and no user session");
    $self->render( status => 400, json => { error => "no authentication credentials or session supplied" } );
}

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

sub check_session {
    my $self = shift;

    # XXX check session here
    $self->app->log->debug("no valid session");
    return 0;
}


1;
