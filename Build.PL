use Module::Build;

Module::Build->new(
    module_name     => "String::Defer",
    license         => "bsd",
    requires        => {
    },
    build_requires  => {
        "Test::More"        => "0.65",
    },
)->create_build_script;
