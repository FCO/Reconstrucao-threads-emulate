use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'threads::emulate',
    AUTHOR              => q{Fernando Corrêa de Oliveira <fco@cpan.org>},
    VERSION_FROM        => 'lib/threads/emulate.pm',
    ABSTRACT_FROM       => 'lib/threads/emulate.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'threads-emulate-*' },
);
