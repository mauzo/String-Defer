use Module::Build;

Module::Build->new(
    module_name     => "String::Defer",
    license         => "bsd",
    requires        => {
        "Exporter"          => "5.57",
    },
    build_requires  => {
        "Test::More"        => "0.65",
        "Test::Exception"   => "0.31",
        "Test::Exports"     => "1",
    },
    meta_merge      => {
        resources   => {
            repository => "http://github.com/mauzo/String-Defer",
            bugtracker => "https://rt.cpan.org/Public/Dist/Display.html?Name=String-Defer",
        },
    },
)->create_build_script;
