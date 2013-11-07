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
  $rest->get('/items')->to(controller => 'REST', action => 'get_items');
  $rest->post('/items')->to(controller => 'REST', action => 'post_item');
  $rest->get('/items/:id')->to(controller => 'REST', action => 'get_item_id');
  $rest->put('/items/:id')->to(controller => 'REST', action => 'put_item_id');
  $rest->delete('/items/:id')->to(controller => 'REST', action => 'delete_item_id');

  # Normal route to controller
  # $r->get('/')->to('example#welcome');
}

1;
