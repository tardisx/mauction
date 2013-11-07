package MAuction::Web::Controller::User;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';

use MAuction::DB::User::Manager;

sub check_user {
    my $self  = shift;
    my $token = $self->req->headers->header('X-API-Token');
    if (! $token) {
        $self->app->log->error("no token supplied");
        $self->render( status => 400, json => { error => "invalid api token" } );
        return;
    }

    $self->app->log->debug("looking for user with token $token");
    my $users = MAuction::DB::User::Manager->get_users(
        query => [ api_token => $token ]
    );
    if (! $users || !@$users) {
        $self->render( status => 400, json => { error => "invalid api token" } );
        return;
    }
    $self->stash->{user} = $users->[0];
    return 1;
}


1;
