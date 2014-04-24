package MAuction::DB;

use strict;
use warnings;

use Rose::DB;
use base 'Rose::DB';

=head1 NAME

MAuction::DB - Rose::DB subclass to manage DB connections

=head1 DESCRIPTION

Provide DB connectivity to the system.

See L<Rose::DB> for details.

=cut

# Use a private registry for this class
__PACKAGE__->use_private_registry;

# Set the default domain and type
__PACKAGE__->default_domain('development');
__PACKAGE__->default_type('Pg');

# Register the data sources

# Development:
__PACKAGE__->register_db(
  domain   => 'development',
  type     => 'Pg',
  driver   => 'Pg',
  database => 'mauction',
  schema   => 'mauction',
  pg_enable_utf8 => 1,
  print_error => 0,
);


1;
