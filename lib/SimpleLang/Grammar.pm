package SimpleLang::Grammar;
use strict;
use Marpa::R2;
use Scalar::Util qw( blessed );
use Data::Printer {
    class => {
        expand     => 'all'
	}
};


our $grammar = Marpa::R2::Scanless::G->new({
  source => \q{
    :default ::= action => [values]
    lexeme default = latm => 1

    Expression ::= String bless => String
               | Number                       bless => Number
               |  ('(') Expression (')')       action => ::first assoc => group
               ||  Expression ('*') Expression  bless => Multiply
               |  Expression ('/') Expression   bless => Divide
               ||   Expression ('+') Expression bless => Add
               |   Expression ('-') Expression  bless => Subtract
               ||   Function Expression          bless => Function

	Function ::= FunctionName
	FunctionName ~ 'hex' | 'print' | 'debug'
	String ::= ('"')WordList('"')
	WordList ::= Word
	Word ~ [^"]+
	Number ::= HexNumber action => parse_hex
			|| IntegerNumber action => parse_integer
	        || DecimalNumber action => parse_decimal
	DecimalNumber ::= IntegerNumber('.')IntegerNumber
	IntegerNumber ~ [\d]+
	HexNumber     ~ '0x' HexDigits
	HexDigits     ~ [0-9A-Fa-f]+
    Whitespace ~ [\s]+
    :discard ~ Whitespace
  },
  bless_package => 'SimpleLang',
});



sub SimpleLang::Function::evaluate {
	my $self = shift;
	my $func = $self->[0]->[0];
	#warn $func;
	if ( $func eq 'hex' ) {
		my $hex = sprintf("0x%x",$self->[1]->evaluate);
		return $hex;
	} elsif ( $func eq 'print' ) {
		print $self->[1]->evaluate, "\n";
	} elsif ( $func eq 'debug' ) {
    	&p($self->[1]);
		print $self->[1]->evaluate, "\n";
	}
}

sub SimpleLang::String::evaluate {
	my $self = shift;
	return "$self->[0]->[0]->[0]";
}

sub SimpleLang::Number::evaluate { my $self = shift;
  return 0 + $self->[0]
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
  return $self->[0]->evaluate + $self->[1]->evaluate
}
sub SimpleLang::Subtract::evaluate { my $self = shift;
  return $self->[0]->evaluate - $self->[1]->evaluate
} 
sub SimpleLang::DecimalNumber::parse_number { my $self = shift;
	warn $self->[0];
	#return $self->[0]->evaluate - $self->[1]->evaluate
} 
sub SimpleLang::HexNumber::parse_hex { my $self = shift;
	warn $self->[0];
	#return $self->[0]->evaluate - $self->[1]->evaluate
}

1;
