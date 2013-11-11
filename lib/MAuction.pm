package MAuction;
use Mojo::Base 'Mojolicious';
use Authen::Simple;

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->plugin('Config', file => 'etc/mauction.conf');

  my $auth_class      = $self->config->{auth}->{module};
  my $auth_class_args = $self->config->{auth}->{args};

  eval "require $auth_class" || die $@;

  my $authenticator = $auth_class->new(%$auth_class_args, log => $self->app->log);
  $self->defaults(authen => $authenticator);

  push @{$self->app->routes->namespaces}, 'MAuction::Web::Controller';

  # Router
  my $r = $self->routes;

  # REST interface
  # They are rooted at /rest
  my $rest = $r->bridge->to(controller => 'User', action => 'check_user')->bridge('/rest/v1');

  # items
  $rest->post('/items')->to(controller => 'REST::Items', action => 'post');
  $rest->get('/items/:id')->to(controller => 'REST::Items', action => 'get_one');
  $rest->get('/items')->to(controller => 'REST::Items', action => 'get_collection');
  $rest->delete('/items/:id')->to(controller => 'REST::Items', action => 'delete');
  $rest->put('/items/:id')->to(controller => 'REST::Items', action => 'put');

  # bids
  $rest->post('/items/:item_id/bids')->to(controller => 'REST::Bids', action => 'post');
  $rest->get('/items/:item_id/bids')->to(controller => 'REST::Bids', action => 'get_collection');

  # web ui
  # unauthenticated parts
  $r->get('/user/login')->to(controller => 'User', action => 'login')->name('user-login');
  $r->post('/user/login')->to(controller => 'User', action => 'login')->name('user-login-post');

  # requires session
  my $ui = $r->bridge->to(controller => 'User', action => 'check_user_with_redirect')->bridge('/');
  $ui->get('/')->to(controller => 'Home', action => 'index')->name('home');
}

1;
