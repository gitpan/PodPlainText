use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => "Pod::PlainText",
    DISTNAME  => "PodPlainText",
    VERSION   => "0.01",
    SKIP      => [qw(static dynamic)],
    linkext   => {LINKTYPE => ''},
    INSTALLDIRS => 'perl',
    PM        => { "PlainText.pm" => '$(INST_LIB)/Pod/PlainText.pm' },
    PL_FILES  => { "podplaintext.PL" => "podplaintext" }
);
