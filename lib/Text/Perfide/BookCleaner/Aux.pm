package Text::Perfide::BookCleaner::Aux;
use warnings; use strict;
use Biblio::Thesaurus;
#use Data::Dumper;

#our %dicnorm = ();
#our @ALONE= ();
#our @ALONE_OR_NUMBER= ();
#our @NUMBER_RIG= ();
#our @NUMERAL=();

$INC{'Text/Perfide/BookCleaner/Aux.pm'} =~ m{/Aux\.pm$};
my $the = "$`/capitulos.the";

sub new{
	my $proto =shift;
	my $class = ref($proto) || $proto;
	my $self 					= {};
	$self->{'dicnorm'} 			= {};
	$self->{'ALONE'} 			= [];
	$self->{'ALONE_OR_NUMBER'} 	= [];
	$self->{'NUMBER_RIG'} 		= [];
	$self->{'NUMERAL'} 			= [];
	$self->{'_sect'} 			= [];
	bless($self,$class);
	$self->_load_thesaurus();
	return $self;
}

sub dicnorm			{ my $self = shift; $self->{'dicnorm'} 			= shift if @_; return $self->{'dicnorm'}; 			}
sub ALONE			{ my $self = shift; $self->{'ALONE'} 			= shift if @_; return $self->{'ALONE'}; 			}
sub ALONE_OR_NUMBER	{ my $self = shift; $self->{'ALONE_OR_NUMBER'} 	= shift if @_; return $self->{'ALONE_OR_NUMBER'}; 	}
sub NUMBER_RIG		{ my $self = shift; $self->{'NUMBER_RIG'} 		= shift if @_; return $self->{'NUMBER_RIG'}; 		}
sub NUMERAL			{ my $self = shift; $self->{'NUMERAL'} 			= shift if @_; return $self->{'NUMERAL'}; 			}
sub _sect			{ my $self = shift; $self->{'_sect'} 			= shift if @_; return $self->{'_sect'}; 			}


sub _load_thesaurus{
	my $self = shift;
	my @l=qw{ PT EN ES FR DE IT RU PL};
	my %l; @l{@l}=@l;

	my $obj = thesaurusLoad($the);

	my %handler = ( 
    	#-end      => sub { $pattfile .= "\n}\n";},
    	#-eachTerm => sub { "\n______________ $term $_"},
    	-default  => sub {
    	 if( $l{$rel}){
    	     for(@terms){ 
    	        $self->dicnorm->{$_} = $term;
    	        if   ($obj->hasRelation($term,"BT","_alone"))           { push @{$self->ALONE},$_ 			if active($rel) }
    	        elsif($obj->hasRelation($term,"BT","_alone_or_number")) { push @{$self->ALONE_OR_NUMBER},$_ if active($rel)	}
    	        elsif($obj->hasRelation($term,"BT","_number_rig"))      { push @{$self->NUMBER_RIG},$_ 		if active($rel) }
    	        elsif($obj->hasRelation($term,"BT","_numeral"))         { push @{$self->NUMERAL},$_ 		if active($rel)	}
    	        else                                                    { push @{$self->_sect},$_ 			if active($rel) }
    	     }   
    	   }   
    	 else { "$rel ".join(", ",@terms) }
    	 }   
	);
	$obj->downtr(\%handler);
}

sub active{
 1;
}

1; 

__END__

=pod

=head1 NAME

Text::Perfide::BookCleaner::Aux

=head1 VERSION

version 0.01

=head1 AUTHOR

Jose Joao <jj@di.uminho.pt>

Andre Santos <andrefs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jose Joao <jj@di.uminho.pt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
