package MAuction::DB::CM;

use base 'Rose::DB::Object::ConventionManager';

use Data::Dumper;
$Data::Dumper::Indent = 0;

sub auto_foreign_key_name {
    my ($class, $name, $kcol) = @_[1,2,3];

    if ($class eq 'MAuction::DB::User') {
        if ($name eq 'items_current_winner_fkey') {
            return 'current_winner_user';
        }
        if ($name eq 'items_user_id_fkey') {
            return 'user';
        }
    }

    return shift->SUPER::auto_foreign_key_name(@_);
}

1;
