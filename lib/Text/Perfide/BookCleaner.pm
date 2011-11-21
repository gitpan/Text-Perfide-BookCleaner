package Text::Perfide::BookCleaner;


use warnings;
use strict;
use utf8;
use Text::Perfide::BookCleaner::Aux;
use Roman;

use base 'Exporter';
our @EXPORT = (qw/gettxt pages sections paragraphs footnotes chars writefile commit paux_pnum_pbr paux_pnum_nopbr paux_pbr paux_hef/);


=head1 NAME

Text::Perfide::BookCleaner - A module for processing books in plain text formats.

=head1 VERSION

Version 0.01_01

=cut

our $VERSION = '0.01_01';

our($commit,$minhf,$simplify,$normpar);
my ($v1,$v2);

$minhf //= 5;
$normpar //= 1;
my $hthreashold = $minhf;
my $fthreashold = $minhf;

my $cp1252_simplification = $simplify;
my $utf_simplification    = $simplify;

my $aux = Text::Perfide::BookCleaner::Aux->new();

#my @_sect = (); 
push(@{$aux->_sect},qw(__BEGIN__ __END__ )) unless $commit;

my $sectpatt			= '(?:'. join("|", ( map {s/([^_])_([^_])/$1 $2/g;$_} @{$aux->_sect})) 				.')' ;
my $sectpattalone		= '(?:'. join("|", ( map {s/([^_])_([^_])/$1 $2/g;$_} @{$aux->ALONE})) 				.')' ;
my $sectpattaloneornum	= '(?:'. join("|", ( map {s/([^_])_([^_])/$1 $2/g;$_} @{$aux->ALONE_OR_NUMBER})) 	.')' ;
my $sectpattnumr		= '(?:'. join("|", ( map {s/([^_])_([^_])/$1 $2/g;$_} @{$aux->NUMBER_RIG})) 		.')' ;
my $ord 				= '(?:'. join("|", ( map {s/([^_])_([^_])/$1 $2/g;$_} @{$aux->NUMERAL})) 			.')' ;

my $nrom = qr{(?:\b(?:[IVXLC]+|x|v|xv)\b)};  ## Roman Number

my $pb     = qr{(?: ?_pb\d*_)};         ## page break mark
my $fn     = qr{(?:_fn\d*_)};           ## footnote mark
my $hyph   = qr{[-‒–—―]};               ## hyphens
my $snline  = qr{(?:\n)};
my $nline   = qr{(?:\n[ \t]*)};         ## \n
my $nline2  = qr{(?:$pb|$nline)$nline}; ## pageBreak \n  or \n\n
my $eopar   = qr{[.:!?’'"…»]};          ##



=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Text::Perfide::BookCleaner;

    my $foo = Text::Perfide::BookCleaner->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 gettxt

Opens a text file and returns its contents.

Optionally, the file encoding may be defined. Default encoding is UTF-8.

Removes all ^M characters.

=cut

sub gettxt{
	my ($file,$enc) = @_;
	local $/;
	undef $/; 
	open(F,$file) or die "Could not open file $file";
	if($enc){ binmode(F,":encoding($enc)")}
	else    { binmode(F,":utf8");}
	my $txt=<F>;
	close F;
	$txt =~ s/[ \t\cM]+\n/\n/g;
	return $txt;
}

=head2 pages

Extracts and removes from text page breaks, headers and footers.

=cut

sub pages{ ## pages, head, foot
 	my $txt = shift;
 	my %dig   = ();
 	my $pbnum = 0;
 	my $pbtab = {};
 	my %head  = ();
 	my %foot  = ();

	my ($dig1,$dig2,$dig3,$dig4);
	($dig1,$txt) = paux_pnum_pbr	($txt,$pbnum,$pbtab);
	($dig2,$txt) = paux_pnum_nopbr	($txt,$pbnum,$pbtab);
	($dig3,$txt) = paux_pbr			($txt,$pbnum,$pbtab);
	($dig4,$txt) = paux_hef			($txt,$pbnum,$pbtab,\%head,\%foot);

	@dig{keys %$dig1} = values %$dig1;
	@dig{keys %$dig2} = values %$dig2;
	@dig{keys %$dig3} = values %$dig3;
	@dig{keys %$dig4} = values %$dig4;
 	return (\%dig,$txt,$pbtab); 
}

=head2 paux_pnum_pbr

Removes pagenumbers + pagebreaks

=cut

sub paux_pnum_pbr {
	my ($txt,$pbnum,$pbtab) = @_;
	my %dig   = ();
    $dig{pagnum_ctrL} = ($txt =~ s{$hyph?\s*\b(\d{1,3})\s*$hyph?\s*\cL}{
		my $pn = $1;
		$pbnum++;
		$pbtab->{$pbnum}{'np'} 		= $pn;
		$pbtab->{$pbnum}{'ctrlL'} 	= 1;
		' _pb'.$pbnum.'_';
	}ge);
	return (\%dig,$txt);
}



=head2 paux_pnum_nopbr

Removes pagenumbers with no pagebreaks

=cut

sub paux_pnum_nopbr {
	my ($txt,$pbnum,$pbtab) = @_;
	my %dig   = ();
	$dig{pbNoCtrlL} = ($txt =~ s{\n\s*$hyph?\s*\b(\d{1,3})\s*$hyph?\s*\n}{
		my $pn = $1;
		$pbnum++;
		$pbtab->{$pbnum}{'np'} = $pn;
		$pbtab->{$pbnum}{'ctrlL'} = 0;
		' _pb'.$pbnum.'_'."\n";
	}ge);
	return (\%dig,$txt);
}


=head2 paux_pbr

Removes single page breaks

=cut

sub paux_pbr {
	my ($txt,$pbnum,$pbtab) = @_;
	my %dig   = ();
 	$dig{ctrL} = ($txt =~ s{\cL}{
		$pbnum++;
		$pbtab->{$pbnum}{'ctrlL'} = 1;
		' _pb'.$pbnum.'_';
	}ge);
	return (\%dig,$txt);

}

=head2 paux_hef

Counts and removes headers and footers

=cut

sub paux_hef {
	my ($txt,$pbnum,$pbtab,$headref,$footref) = @_;
	my (%head,%foot) = (%$headref,%$footref);
	my %dig   = ();

	### has headers and/or footers

	### contagem de headers e footers
    $txt =~ s{(\n+(.*)\n*\s*_pb(\d+)_(.*)\n+)}{
		my ($x,$b,$pbnum,$c)=($1,$2,$3,$4);
		my $header = _n($c);
		my $footer = _n($b);
        $foot{$footer}++ if $footer !~ /^\s*$/;
		$head{$header}++ if $header !~ /^\s*$/; 
		"$x";
	}ge ;

	### remove headers e footers 
    $txt =~ s{(\n+(.*)\n*\s*_pb(\d+)_(.*)\n*)}{
		my ($x,$b,$pbnum,$c)=($1,$2,$3,$4); 
		my $header = _n($c);
		my $footer = _n($b);
		my $result = '';
		if ($foot{$footer} and $foot{$footer} > $fthreashold ) 
                { $pbtab->{$pbnum}{'foot'} = $footer }
		else	{ $result = "\n$b"; 				 }
		$result.=" _pb$pbnum"."_";
		if ($head{$header} and $head{$header} > $hthreashold )	
                { $pbtab->{$pbnum}{'head'} = $header }
		else	{ $result.= "\n$c" if $c; 			 }
		"$result\n";
	}ge ;

	my @aux = map 
		{($head{$_} > 5)? ("($_) = $head{$_}"):()} 
		(sort {$head{$b} <=>  $head{$a}} keys %head );
	$dig{headers}= [@aux] if @aux;
	
	@aux = map 
		{($foot{$_} > 5)? ("($_) = $foot{$_}"):()} 
		(sort {$foot{$b} <=>  $foot{$a}} keys %foot );
	$dig{footers}= [@aux] if @aux;

	### has pagenumber (line with just a number)
	$dig{line_with_num} = ($txt =~ s{\n[ \t]*(\d{1,3})\n}{\n_n_\n}g );

	return (\%dig,$txt);
}

=head2 sections

Detects section titles and breaks.

=cut

sub sections{  ## secções
 my $txt = shift;
 my %dig=();

 ### numeração romana
 $dig{sectionsRom } = ($txt =~ s{$nline($nrom)(?:\s*[.])?$snline}{
								my $norm1 = arabic($1); $norm1 //= $1;
								"\n_sec+Rom:$norm1"."_ $1\n"}gei );
## $dig{num_rom2} = ($txt =~ s{$nline2($nrom)([^'´’])}{\n\n_rom2:$1_'$2'}g );

 ###  secções variadas e ao molho
 $dig{sectionsN}   = ($txt =~ s{$nline2($sectpatt)\s+(\d+|$nrom)}{
								my $norm1 = $aux->dicnorm->{lc($1)}; $norm1 //= $1;
								my $norm2 = arabic($2);
								$norm2 //= $2;
								"\n\n_sec+N:$norm1=$norm2"."_ $1 $2"}gei );
 $dig{sectionsN}    += ($txt =~ s{$nline2(\d+|$nrom)\s+($sectpattaloneornum)$snline}{
								my $norm1 = arabic($1);
								 $norm1 //= $1;
								my $norm2 = $aux->dicnorm->{lc($2)}; $norm2 //= $2;
								"\n\n_sec+N:$norm2=$norm1"."_ $1 $2\n"}gei );

 $dig{sectionsNAN}  = ($txt =~ s{$nline2($sectpattaloneornum)\s+(\d+|$nrom)}{
								my $norm1 = $aux->dicnorm->{lc($1)}; $norm1 //= $1;
								my $norm2 = arabic($2);
								$norm2 //= $2;
								"\n\n_sec+NAN:$norm1=$norm2"."_ $1 $2"}gei );

 $dig{sectionsNNR}  = ($txt =~ s{$nline2($sectpattnumr\s+(\d+|$nrom))}{
								my $norm1 = $aux->dicnorm->{lc($1)}; $norm1 //= $1;
								my $norm2 = arabic($2);
								$norm2 //= $2;
								"\n\n_sec+NNR:${norm1}=${norm2}"."_ $1 $2"}gei );

 $dig{sectionsNA}   = ($txt =~ s{$nline2($sectpattalone)$snline}{
								my $norm = $aux->dicnorm->{lc($1)}; $norm //= $1;
								"\n\n_sec+NA:${norm}_ $1\n"}gei );

# $dig{sectionsN}+= ($txt =~ s{$nline($sectpatt\s+(\d+|$nrom))}{\n_sec-N:$1_}gi );

 $dig{sectionsO} = ($txt =~ s{$nline2($sectpatt)\s+($ord)$snline}{
								my $norm1 = $aux->dicnorm->{lc($1)}; $norm1 //= $1;
								my $norm2 = $aux->dicnorm->{lc($2)}; $norm2 //= $2;
								"\n\n_sec+O:$norm1=$norm2"."_ $1 $2\n"
								}gei 
					);
 $dig{sectionsO} += ($txt =~ s{$nline2($sectpattaloneornum)\s+($ord)$snline}{
								my $norm1 = $aux->dicnorm->{lc($1)}; $norm1 //= $1;
								my $norm2 = $aux->dicnorm->{lc($2)}; $norm2 //= $2;
								"\n\n_sec+O:$norm1=$norm2"."_ $1 $2\n"
								}gei );

 $dig{sections}  = ($txt =~ s{$nline2($sectpatt)\b}{
								my $norm = $aux->dicnorm->{lc($1)}; $norm //= $1;
								"\n\n_sec:${norm}_ $1"}gei );

 $dig{sectionsO} += ($txt =~ s{$nline2($ord)\s+($sectpatt)\b}{
								my $norm1 = $aux->dicnorm->{lc($1)}; $norm1 //= $1;
								my $norm2 = $aux->dicnorm->{lc($2)}; $norm2 //= $2;
								"\n\n_sec+O:$norm2=$norm1"."_ $1 $2"
								}gei );
# $dig{sectionsO}+= ($txt =~ s{$nline($ord)\s+($sectpatt)\b}{\n_sec-O:$2=$1_}gi );

 $dig{sectionsHR } = ($txt =~ s{$nline(\S)\1{30,}$snline}{\n_sec+HR:$1_\n}g );

 $dig{sectionsHTML} = ($txt =~ s{<h([1-3])>(.*?)</h\1>}{\n_sec+HTML$1_ $2}gi );
 $dig{sectionsHTML} += ($txt =~ s{<title>(.*?)</title>}{\n_sec+HTMLtit_ $1}gi );

 return (\%dig,$txt); 
}

=head2 paragraphs

Detects and normalizes paragraph notation.

=cut

sub paragraphs{  ## paragrafos
 ##TODO something is not working. testing with _FR_15 and diff with mkbookclear's output gives different results

 my $txt = shift;
 my %dig=(word_per_indent => 100000); # infinity
 $dig{emptylines}=0;

 ### calculating empty lines
 while($txt =~ m{\n(\s*)\n(_sec.*\s*)?}g){ $dig{emptylines}++ unless $2 }
 for($txt =~ m{(\S.*\n)}g)               { $dig{lines}++ }
 for($txt =~ m{($eopar\n)}g)             { $dig{lines_w_pont}++ }
 
 my %indent=();
 ### calculating indentations
 while($txt =~ m{\S\n([ \t]*)\S}g){ $indent{length($1)}++; }
 ### debug  $txt =~ s{(\S\n)([ \t]*)(\S)}{$1=indent$2=$3}g;
 my @aux = map 
          {($_ != 1 && $_ < 10 && $indent{$_} > 10)? ([$_ ,$indent{$_}]):()} 
          (sort {$indent{$b} <=>  $indent{$a}} keys %indent );
 ### print Dumper(\@aux);
 
 ### how many words? 5
 $dig{words}= ($txt =~ s{(\S+)}{$1}g );

 $dig{word_per_emptyline}= $dig{words} / (1+ $dig{emptylines} );
 $dig{word_per_line}     = $dig{words} / ( $dig{lines} );
 $dig{word_per_indent}   = $dig{words} / ( $aux[1][1] )
       if (defined($aux[0]) && $aux[0][0] == 0 && $aux[1]) ;

 if($dig{word_per_emptyline} > 150 &&
    $dig{word_per_indent}    > 10  &&
    $dig{word_per_indent}    < 100 ){ $dig{To_be_indented}=1 ;
      $txt =~ s{((?:$pb|$eopar)\n)([ \t]{2,10}\S)}{$1\n$2}g  if $normpar;
    }
 elsif($dig{word_per_emptyline} > 150 &&
    $dig{word_per_line}    > 10  &&
    $dig{word_per_line}    < 100 &&
    $dig{lines_w_pont} / $dig{lines} > 0.6 ){ $dig{To_be_lineseparated}=1 ;
      $txt =~ s{((?:$eopar)\n)([ \t]*\S)}{$1\n$2}g           if $normpar;
    }
 return (\%dig,$txt);
}

=head2 footnotes

Detects and removes footnotes.

=cut

sub footnotes{  ## footnotes
    my %dig=();
    my $txt = shift;
    my $footnotes = {};
    my $fnnum = 0;

    my $fn1 = qr{<<(\d+)>>};
    my $fn2 = qr{\[(\d+)\]};
    my $fn3 = qr{\^(\d+)};
    my $fns = qr{(?:$fn1|$fn2|$fn3)};
    my $end = qr{(\n\n)|$fns};

    $dig{fn_ext} = $txt =~ s{^\s*$fns.*?\n\n}{
        my $fn = $1;
        $fn //= $2;
        $fn //= $3;
        $fnnum++;
                                               
        '_fne'.$fnnum."_\n";
    }gmse;

    # $dig{fn_ext} = $txt =~ s{^\s*$fns.*?$end}{
    #   my $fn = $1;
    #   $fn //= $2;
    #   $fn //= $3;
    #   $fnnum++;

    #   my $fn_end = $4;
    #   $fn_end //= $5;
    #   $fn_end //= $6;
    #   $fn_end //= $7;
    #   '_fne'.$fnnum.'_'."\n$fn_end";
    # }gmse;

 	$dig{fn_refs} = $txt =~ s{$fn1|$fn2|$fn3}{
        my $fn = $1;
        $fn //= $2;
        $fn //= $3;
        $fnnum++;
        '_fnr'.$fnnum.'_';
    }ge;

    #$dig{fn_refs} .= $txt =~ s{\[(\d+)\]}{
    #   my $fn = $1;
    #   $fnnum++;
    #   '_fn'.$fnnum.'_';
    #}ge;

	# utf8::encode($txt); ##TODO isto e' boa ideia?
    return (\%dig,$txt,$footnotes);
}

=head2 chars

Several character-level operations: replacing non-ISO characters 

=cut

sub chars{  ## char level
    my %dig=();
    my $txt=shift;

 ### _ vs -   
 $dig{under_vs_hifen} =($txt =~ s{(\b_\b)}{_-_}g);

 $dig{fix_retic} = ($txt =~ s{\. \. ?\.|\. ?\. \.}{...}g);

 ### has word transliniations?  
 ### $dig{word_tr}= ($txt =~ s{(\w)-(\n[ \t]*)(\S+)}{$1$3!!!!$2}g );

 ## Strange char
 $dig{charNonIso}= ($txt =~ s{([\x80-\x99])}{$1_cp1252_}g );

 $dig{char_dig}+= ($txt =~ s{ﬁ}{fi}g );
 $dig{char_dig}+= ($txt =~ s{ﬂ}{fl}g );
 $dig{char_dig}+= ($txt =~ s{ﬀ}{ff}g );

 ## Utf simplification...

 if($cp1252_simplification){ 
   $txt =~ s/\x85/…/g;
   $txt =~ s/\x80/€/g;
   $txt =~ s/\x8C/OE/g;
   $txt =~ s/\x91/‘/g ; # / LEFT SINGLE QUOTATION MARK
   $txt =~ s/\x92/’/g ; # / RIGHT SINGLE QUOTATION MARK
   $txt =~ s/\x93/“/g ; # / LEFT DOUBLE QUOTATION MARK
   $txt =~ s/\x94/”/g ; # / RIGHT DOUBLE QUOTATION MARK
   $txt =~ s/\x95/•/g ; # / BULLET
   $txt =~ s/\x96/-/g ; # / EN DASH
   $txt =~ s/\x97/-/g ; # / EM DASH
 }


 if($utf_simplification){
   $txt =~ s/…/.../g; #     8230 => "..."   ,      # …
                      #     8364 => " Euros "   ,  # €
   $txt =~ s/’/'/g;   #     8217 => "'" ,          # ’    226?
   $txt =~ s/‘/'/g;   #     8216 => "'" ,          # ‘
   $txt =~ s/“/"/g;   #     8220 => "\"" ,         # “
   $txt =~ s/”/"/g;   #     8221 => "\"" ,         # ”

   $txt =~ s/‐/-/g;   #     8208 => "-" ,          # ‐
   $txt =~ s/‑/-/g;   #     8209 => "-" ,          # ‑
   $txt =~ s/–/--/g;  #     8211 => "--" ,         # –
   $txt =~ s/—/--/g;  #     8212 => "--" ,         # —

   $txt =~ s/—/--/g;  #     8212 => "--" ,         # —
   $txt =~ s/⇒/=>/g;  #     
   $txt =~ s/→/->/g;  #     
   $txt =~ s/•/*/g;   #
 }

	my $digref;
	($digref,$txt) = translin($txt);
	@dig{keys %$digref} = values %$digref;
	return (\%dig,$txt);
}

=head2 translin

Deals with translineations (words split across lines caused by line-wrapping)
and transpaginations (same situation but for pages).

=cut

sub translin {
    my %dig = ();
    my $txt = shift;

	my $init_s = qr/ {1,6}|\t\t?/;									# Spaces at the beginning of line -- max 6 spaces or 2 tabs
	my $lower = qr{[a-z]};											# Lowercase letters -- #TODO accentuated/russian chars

	my $tlpat  = qr{(\S*\w)-\n($init_s?)($lower\S*)};				# Normal translineation
	my $dtlpat = qr{(\S*\w)-\n($init_s?)-($lower\S*)};				# Double hifen translineation
	my $tppat  = qr{(\S*\w)-(\s_pb\d+_)\n($init_s?)($lower\S*)};	# Transpagination
	my $dtppat = qr{(\S*\w)-(\s_pb\d+_)\n($init_s?)-($lower\S*)};	# Double hifen transpagination

 	$dig{translin}  = ($txt =~ s{$tlpat} {"\n$2$1$3"}gei	);
 	$dig{translin} += ($txt =~ s{$dtlpat}{"\n$2$1-$3"}gei	);
 	$dig{transpag}  = ($txt =~ s{$tppat} {"$2\n$3$1$4"}gei	);
 	$dig{transpag} += ($txt =~ s{$dtppat}{"$2\n$3$1-$4"}gei	);
								
	return (\%dig,$txt);
	#return $txt;
}


=head2 commit

Returns a text with all changes commited (removes marks left by other functions).

=cut

sub commit{
    #my %dig=();
    my $txt=shift;
	$txt =~ s/^.*?\n__BEGIN__\n//s;
	$txt =~ s/\n__END__\n.*$/\n/s;
	$txt =~ s/$pb/ /g;
	$txt =~ s/$fn/ /g;
	$txt =~ s/_cp1252_//g;
	return $txt;
}

=head2 writefile

Writes text in file pointed by given file descriptor (default enconding UTF8).

=cut

sub writefile{
	my ($txt,$fd)=@_;
	$fd = *STDOUT unless $fd;	
	binmode($fd,":utf8");  
	print $fd $txt;
}

## Auxiliary functions

sub _n{ my $a = shift;
  $a =~ s/\s+/ /g;
  $a =~ s/\d+/_NUM_/g;
  $a; 
}


1; 

__END__

=head1 AUTHOR

Jose Joao, C<< <jj at di.uminho.pt> >>

Andre Santos, C<< <andrefs at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-bookcleaner at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-BookCleaner>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Perfide::BookCleaner


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-BookCleaner>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-BookCleaner>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-BookCleaner>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-BookCleaner/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Jose Joao.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

# End of Text::Perfide::BookCleaner
