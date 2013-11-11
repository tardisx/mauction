package Test::MAuction::Authenticator;

sub new { return bless {}, __PACKAGE__ };

sub authenticate {
  my $self = shift;
  my $u = shift;
  my $p = shift;
   
  return $u eq $p;
}

1;


