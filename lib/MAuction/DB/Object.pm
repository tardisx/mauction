#
# Note that UNLIKE the other files in this directory, this one is not
# automatically generated - take care of it.
#
package MAuction::DB::Object;

use strict;
use warnings;

use MAuction::DB;

use Rose::DB::Object::Helpers 'insert_or_update', 'as_tree';

use base qw(Rose::DB::Object);

sub init_db { return MAuction::DB->new; }

1;
