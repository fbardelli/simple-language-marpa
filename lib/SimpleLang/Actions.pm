package SimpleLang::Actions;


sub parse_decimal {
  my $self = shift;
  use Data::Dumper;
  my $args = shift;
  return 0 + "$args->[0].$args->[1]";
}

sub parse_integer {
  my $self = shift;
  return shift;
}

sub parse_hex {
  my $self = shift;
  my $num = shift;
  $num =~ s/^0x//;
  my $val = sprintf("%d", hex($num));
}

1;
