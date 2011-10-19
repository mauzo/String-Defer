#!/usr/bin/perl

use warnings;
use strict;

use String::Defer;
use t::Utils;

my $targ    = "foo";
my $defer   = eval { String::Defer->new(\$targ) };
my $defer2; # this needs to be declared before the eval"" below

ok defined $defer,          "new accepts a scalar ref";
is_defer $defer,            "new returns a String::Defer"
    or BAIL_OUT "can't even create an object!";

try_forcing $defer, "foo",  "new object";
is_defer $defer,            "forcing doesn't affect the object";

$targ = "bar";
is $defer->force, "bar",    "forcing is deferred";
is "$defer", "bar",         "stringify is deferred";

sub check_expr {
    my ($what, $pat, $setup) = @_;

    my $want = $setup->("foo", $pat);
    my $str = eval $what;

    unless (ok defined $str,    "$what succeeds") {
        diag "\$\@: $@";
        return;
    }
    is_defer $str,              "$what returns an object"
        or return;
    is "$defer", "foo",         "$what doesn't affect the original";

    try_forcing $str, $want,    $what;

    $want = $setup->("bar", $pat);
    try_forcing $str, $want,    "deferred $what";
}

check_expr @$_, sub { 
    ($targ, my $want) = @_;
    $want =~ s/%/$targ/g;
    $want;
} for (
    ['$defer->concat("B")',                 "%B"    ],
    ['$defer->concat("A", 1)',              "A%"    ],
    ['$defer->concat("B")->concat("A", 1)', "A%B"   ],

    ['$defer . "B"',                        "%B"    ],
    ['"A" . $defer',                        "A%"    ],
    ['"A" . $defer . "B"',                  "A%B"   ],

    ['"$defer B"',                          "% B"   ],
    ['"A $defer"',                          "A %"   ],
    ['"A $defer B"',                        "A % B" ],
);

$defer2 = String::Defer->new(\my $targ2);

check_expr @$_, sub {
    ($targ, my $want) = @_;
    $targ2 = uc $targ;
    $want =~ s/%/$targ/g;
    $want =~ s/#/$targ2/g;
    $want;
} for (
    ['$defer->concat($defer2)',                 "%#"        ],
    ['$defer->concat($defer2, 1)',              "#%"        ],
    ['$defer->concat("A")->concat($defer2)',    "%A#"       ],

    ['$defer . $defer2',                        "%#"        ],
    ['$defer . "A" . $defer2',                  "%A#"       ],
    ['"A" . $defer . $defer2',                  "A%#"       ],
    ['$defer . $defer2 . "A"',                  "%#A"       ],

    ['"${defer}$defer2"',                       "%#"        ],
    ['"$defer A $defer2"',                      "% A #"     ],
    ['"A ${defer}$defer2"',                     "A %#"      ],
    ['"${defer}$defer2 A"',                     "%# A"      ],
    ['"A $defer B $defer2 C"',                  "A % B # C" ],
);

done_testing;
