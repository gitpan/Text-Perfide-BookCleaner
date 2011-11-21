#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
our $secN=0;

#my $out1 = qx{bin/bookcleaner -pipe t/t1.src 2>/dev/null};
my $out1 = qx{blib/script/bookcleaner t/t1.src};
if($out1 =~ m/sectionsN=(\d+)/) { $secN=$1}

is ($secN, 9 , "English Parts and Chapter");
