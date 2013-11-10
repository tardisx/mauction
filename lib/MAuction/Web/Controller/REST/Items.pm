package MAuction::Web::Controller::REST::Items;

use Mojo::Base 'MAuction::Web::Controller::REST';

sub db_class_read   { "MAuction::DB::ItemsWinner" }
sub db_class_write  { "MAuction::DB::Item" }
sub get_method      { "get_items" }
sub get_read_method { "get_items_winners" }
sub post_fields     { qw/name description bid_increment bid_min start_ts end_ts/ }

=head3 POST /rest/v1/items

Create a new auction item.

=head4 Input

=over

=item name

Short name of the item.

=item description

Long description for the item.

=item bid_increment

Minimum amount a new bid must be over the previous one.

=item bid_min

Minimum starting bid.

=item start_ts end_ts

Beginning and ending dates and time for this auction.

=back

=head4 Output

=over 4

=item Status 200

JSON with the created object.

=item Status 400

JSON with a single key 'error' containing the error message.

=back

=cut

1;
