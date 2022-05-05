use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'LWP::Authen::OAuth2::ServiceProvider::Microsoft',
  VERSION_FROM     => 'lib/LWP/Authen/OAuth2/ServiceProvider/Microsoft.pm',
  ABSTRACT_FROM    => 'lib/LWP/Authen/OAuth2/ServiceProvider/Microsoft.pm',
  AUTHOR           => 'Pero Moretti',
  LICENSE          => 'freebsd',
  MIN_PERL_VERSION => '5.008004',
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'LWP::Authen::OAuth2' => '0.19',
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/Pero-Moretti/Perl-LWP-Authen-OAuth2-ServiceProvider-Microsoft.git',
              web  => 'https://github.com/Pero-Moretti/Perl-LWP-Authen-OAuth2-ServiceProvider-Microsoft',
          },
      }})
   : ()
  ),
);
