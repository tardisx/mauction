package MAuction::Web::Controller::REST::Items;

use Time::Duration qw/duration concise/;

use Mojo::Base 'MAuction::Web::Controller::REST';

sub db_class_read   { "MAuction::DB::Item" }
sub db_class_write  { "MAuction::DB::Item" }
sub get_method      { "get_items" }
sub post_fields     { qw/name description bid_increment bid_min start_ts end_ts/ }
sub get_extra_fields { shift; my $item = shift;
                       return (
                           remaining_secs   => ($item->end_ts->epoch - time()),
                           remaining_string => duration($item->end_ts->epoch - time()),
                           remaining_string_concise => concise(duration($item->end_ts->epoch - time()))
                       );
                   }
# when loading items, load up the user object details as well
sub load_with { return ( 'user', 'current_winner_user' ) }

# sanitise the user object, since any other user can see this
sub sanitise {
    shift;
    my $d = shift;
    delete $d->{user_id};
    delete $d->{$_}->{id}        foreach (qw/ user current_winner_user/ );
    delete $d->{$_}->{api_token} foreach (qw/ user current_winner_user /);
}



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
