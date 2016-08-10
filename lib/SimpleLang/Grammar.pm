package SimpleLang::Grammar;
use strict;
use Marpa::R2;
use Scalar::Util qw( blessed );
use Data::Printer {
    class => {
        expand     => 'all'
    }
};

our $_state = {};

our $grammar = Marpa::R2::Scanless::G->new({
  source => \q{
    :default ::= action => [values]
    lexeme default = latm => 1

    Expression ::= String bless => String
               | Variable                      bless => Variable
               | Number                        bless => Number
               |  ('(') Expression (')')       action => ::first assoc => group
               || Expression ('*') Expression  bless => Multiply
               |  Expression ('/') Expression  bless => Divide
               || Expression ('+') Expression  bless => Add
               |  Expression ('-') Expression  bless => Subtract
               || Array                        bless => Array
               || Array ('.') ArrayOp          bless => ArrayOp
               || Variable ('.') ArrayOp       bless => ArrayOp
               || Function Expression          bless => Function
               || Function                     bless => Function
               || Assignment                   bless => Assignment

  Function      ::= FunctionName
  FunctionName  ~ 'hex' | 'print' | 'debug' | 'exit'
  ArrayOp       ::= ArrayOpName
  ArrayOpName   ~ 'length' | 'pop'
  Assignment    ::= Variable ('=') Expression
  Variable      ::= VarName
  Array         ::= ('[' ']') action => []
                 | ('[') Elements (']')
  Elements     ::= Expression+ action => ::array separator => [,]
  VarName       ~ [A-Za-z]+  
  String        ::= ('"')WordList('"')
  WordList      ::= Word
  Word          ~ [^"]+
  Number        ::= HexNumber action => parse_hex
                || IntegerNumber action => parse_integer
                || DecimalNumber action => parse_decimal
  DecimalNumber ::= IntegerNumber('.')IntegerNumber
  IntegerNumber ~ [\d]+
  HexNumber     ~ '0x' HexDigits
  HexDigits     ~ [0-9A-Fa-f]+
  Whitespace    ~ [\s]+
  :discard      ~ Whitespace
  },
  bless_package => 'SimpleLang',
});



sub SimpleLang::Function::evaluate {
  my $self = shift;
  my $func = $self->[0]->[0];
  use Data::Dumper;
  #warn Dumper $self;
  if ( $func eq 'hex' ) {
    my $hex = sprintf("0x%x",$self->[1]->evaluate);
    return $hex;
  } elsif ( $func eq 'print' ) {
    print $self->[1]->evaluate, "\n";
  } elsif ( $func eq 'debug' ) {
    &p($self->[1]);
    print $self->[1]->evaluate, "\n";
  } elsif ( $func eq 'exit' ) {
    exit(0);
  }
}

sub SimpleLang::ArrayOp::evaluate {
  my $self = shift;
  my $array;
  if (ref $self->[0]->[0]) {
    $array = $self->[0]->[0];
  } elsif (length $self->[0]->[0]){
    $array = $_state->{variable}{$self->[0]->[0]};
  } else {
    die "invalid array";
  }
  my $func  = $self->[1]->[0];
  use Data::Dumper;
  warn "eval arrayop";
  warn Dumper $self->[0];
  warn "func $func";
  if ( $func eq 'length' ) {
    warn "len";
    return scalar @$array;
  } elsif ( $func eq 'pop' ) {
    warn "pop'd";
    return pop @$array;
  }
}

sub SimpleLang::String::evaluate {
  my $self = shift;
  return "$self->[0]->[0]->[0]";
}

sub SimpleLang::Array::evaluate {
  my $self = shift;
  warn Dumper $self;
  return $self->[0]->[0];
}

sub SimpleLang::Number::evaluate {
  my $self = shift;
  return 0 + $self->[0]
}

sub SimpleLang::Variable::evaluate {
  my $self = shift;
  warn Dumper ["var", $self, $self->[0]];
  return $_state->{variable}{$self->[0]->[0]};
}


sub SimpleLang::Multiply::evaluate { my $self = shift;
  return $self->[0]->evaluate * $self->[1]->evaluate
}
sub SimpleLang::Divide::evaluate { my $self = shift;
  return $self->[0]->evaluate / $self->[1]->evaluate
}
sub SimpleLang::Add::evaluate { my $self = shift;
  if ( blessed($self->[0]) eq 'SimpleLang::String' || blessed($self->[1]) eq 'SimpleLang::String') {
    return join("",$self->[0]->evaluate,$self->[1]->evaluate);
  }
  warn Dumper ["ADD",$self->[0], $self->[1]];
  return $self->[0]->evaluate + $self->[1]->evaluate
}
sub SimpleLang::Subtract::evaluate { my $self = shift;
  return $self->[0]->evaluate - $self->[1]->evaluate
} 
sub SimpleLang::Assignment::evaluate { 
  my $self = shift;
  use Data::Dumper;
  warn Dumper $self;
  my $ret = $_state->{variable}{$self->[0]->[0]->[0]} = $self->[0]->[1]->evaluate;
  warn "STATE:" . Dumper $_state;
  return $ret;
}

sub SimpleLang::DecimalNumber::parse_number {
  my $self = shift;
  warn $self->[0];
  #return $self->[0]->evaluate - $self->[1]->evaluate
} 
sub SimpleLang::HexNumber::parse_hex { my $self = shift;
  warn $self->[0];
  #return $self->[0]->evaluate - $self->[1]->evaluate
}

1;
