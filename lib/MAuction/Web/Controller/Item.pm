package MAuction::Web::Controller::Item;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';

use MAuction::DB::Item;

sub item_without_name {
    my $self = shift;
    my $id   = $self->param('id');

    my $item = MAuction::DB::Item->new(id => $id)->load(speculative => 1);
    if ($item) {
        return $self->redirect_to($self->url_for('item-by-id-and-name', id => $id, name => $item->url_name));
    }
    $self->render_not_found;
}

sub item_name {
    my $self = shift;
    my $id   = $self->param('id');
    my $name = $self->param('name');

    my $item = MAuction::DB::Item->new(id => $id)->load(speculative => 1);
    if (! $item) {
        return $self->redirect_to($self->url_for('item-by-id-and-name', id => $id, name => $item->url_name));
    }

    if ($item->url_name ne $name) {
        # if the URL name is wrong, redirect them (so bookmarks continue to work)
        return $self->redirect_to($self->url_for('item-by-id-and-name', id => $id, name => $item->url_name));
    }

    # we are all good
    $self->stash->{item} = $item;
    $self->render(template => 'item/view');
}


1;
