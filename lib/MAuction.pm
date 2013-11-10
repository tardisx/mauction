package MAuction;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

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

  # Normal route to controller
  # $r->get('/')->to('example#welcome');
}

1;
