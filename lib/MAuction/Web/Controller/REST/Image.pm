package MAuction::Web::Controller::REST::Image;

use Mojo::Base 'MAuction::Web::Controller::REST';

sub query_args      { 'item_id' => shift->param('item_id') }
sub db_class_read   { "MAuction::DB::ImgurPicture" }
sub db_class_write  { "MAuction::DB::ImgurPicture" }
sub get_method      { "get_imgur_pictures" }
sub get_read_method { "get_imgur_pictures" }
sub post_fields     { qw/imgur_code/ }

1;
