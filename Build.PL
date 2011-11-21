use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::Perfide::BookCleaner',
    license             => 'perl',
    dist_author         => q{Jose Joao <jj@di.uminho.pt>},
    dist_version_from   => 'lib/Text/Perfide/BookCleaner.pm',
    build_requires => {
        'Biblio::Thesaurus' => 0,
        'Test::More' => 0,
		'Roman' => 0,
    },
#    PL_files => { 'bin/mkbookcleaner.PL' => 'bin/mkbookcleaner' },
    add_to_cleanup      => [ 'Text-BookCleaner-*' ],
    create_makefile_pl => 'traditional',
);

$builder->add_build_element('the');
$builder->create_build_script();
