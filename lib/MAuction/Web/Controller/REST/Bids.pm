package MAuction::Web::Controller::REST::Bids;

use Mojo::Base 'MAuction::Web::Controller::REST';

sub query_args      { 'item_id' => shift->param('item_id') }
sub db_class_read   { "MAuction::DB::Bid" }
sub db_class_write  { "MAuction::DB::Bid" }
sub get_method      { "get_bids" }
sub get_read_method { "get_bids" }
sub post_fields     { qw/amount/ }

1;
