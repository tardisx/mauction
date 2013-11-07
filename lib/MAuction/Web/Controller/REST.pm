package MAuction::Web::Controller::REST;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';

sub get_one {}

sub get_collection {}

sub post {
    my $self = shift;
    my $class = $self->db_class;
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
