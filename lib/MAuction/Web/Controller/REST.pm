package MAuction::Web::Controller::REST;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';

sub get_one {
    my $self = shift;
    my $class = $self->db_class_read;
    my $id    = $self->stash('id');

    if (! $id) {
        return $self->render(status => 404, json => { error => 'no id provided' } );
    }
    if ($id !~ /^\d+$/) {
        return $self->render(status => 400, json => { error => "bad id $id provided" } );
    }

    eval "require $class";
    die $@ if $@;

    my $new = $class->new(id => $id)->load(speculative => 1);
    if (! $new) {
        return $self->render(status => 404, json => { error => 'no such object id: '.$id });
    }

    return $self->render(status => 200, json => $new->as_tree );
}

sub get_collection {
    my $self = shift;
    my $limit  = $self->param('limit')  || 50;
    my $offset = $self->param('offset') || 0;
    my $sort   = $self->param('sort')   || 'id ASC';

    my $class  = $self->db_class_read . "::Manager";
    eval "require $class";
    die $@ if $@;

    my $method = $self->get_read_method;
    my $collection = $class->$method(
        query   => [ ],
        limit   => $limit,
        offset  => $offset,
        sort_by => $sort
    );

    return $self->render(status => 200, json => [ map { $_->as_tree } @$collection ] );
}

sub delete {
    my $self = shift;
    my $class = $self->db_class_write;
    my $id    = $self->stash('id');

    if (! $id) {
        return $self->render(status => 404, json => { error => 'no id provided' } );
    }
    if ($id !~ /^\d+$/) {
        return $self->render(status => 400, json => { error => "bad id $id provided" } );
    }

    eval "require $class";
    die $@ if $@;

    my $object = $class->new(id => $id)->load(speculative => 1);

    if (! $object) {
        return $self->render(status => 404, json => { error => 'no such object id: '.$id });
    }
    eval { $object->delete };

    if ($@) {
        return $self->render(status => 400, json => { error => $@ });
    }
    return $self->render(status => 200, json => {});
}

sub post {
    my $self = shift;
    my $class = $self->db_class_write;
    my $req   = $self->req->json;

    eval "require $class";
    die $@ if $@;

    my $new = $class->new();
    foreach my $param ($self->post_fields) {
        if ($req->{$param} && ! ref($req->{$param})) {
            eval { $new->$param($req->{$param}) };
            return $self->_render_set_exception($param, $@) if $@;
        }
    }

    if ($new->can('user_id')) {
        $new->user_id($self->stash->{user}->id);
    }

    $self->_eval_save($new);
}

sub put {}

sub _render_set_exception {
    my $self = shift;
    my $field = shift;
    my $exception = shift;
    my $error = $exception;

    if ($exception =~ /invalid timestamp/i) {
        $error = "an invalid timestamp was provided for the field '$field'";
    }

    return $self->render(status => 400, json => { error => $error });
}

sub _eval_save {
    my $self = shift;
    my $obj  = shift;

    eval {$obj->save()};
    my $error = $@;
    if (! $error) {
        return $self->render(json => $obj->as_tree);
    }
    my $error_msg = $error;
    if ($error =~ /null value in column "(\w+)" violates not-null constraint/) {
        $error_msg = "no value provided for required field '$1'";
    }
    elsif ($error =~ /invalid input syntax for type numeric/) {
        $error_msg = "invalid value for numeric field";
    }

    $self->render(status => 400, json => { error => $error_msg });
}

1;
