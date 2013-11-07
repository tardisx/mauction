package MAuction::Web::Controller::REST::Items;

use Mojo::Base 'MAuction::Web::Controller::REST';

sub db_class { "MAuction::DB::Item"; }
sub post_fields { qw/name description bid_increment bid_min start_ts end_ts/; }

1;

1;
