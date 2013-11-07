package MAuction::Web::Controller::REST::Items;

use Mojo::Base 'MAuction::Web::Controller::REST';

sub db_class_read  { "MAuction::DB::ItemsWinner" }
sub db_class_write { "MAuction::DB::Item" }
sub get_method { "get_items" }
sub get_read_method { "get_items_winners" }
sub post_fields { qw/name description bid_increment bid_min start_ts end_ts/ }

1;

1;
