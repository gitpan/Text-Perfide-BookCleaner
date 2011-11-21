#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Text::Perfide::BookCleaner' );
}

diag( "Testing Text::Perfide::BookCleaner $Text::Perfide::BookCleaner::VERSION, Perl $], $^X" );

BEGIN {
    use_ok( 'Text::Perfide::BookCleaner::Aux' );
}

diag( "Testing Text::Perfide::BookCleaner::Aux, Perl $], $^X" );
