#!/usr/bin/perl

use warnings;
use strict;

use String::Defer;
use t::Utils;

my $targ    = "foo";
my $defer   = eval { String::Defer->new(\$targ) };

ok defined $defer,          "new accepts a scalar ref";
is_defer $defer,            "new returns a String::Defer"
    or BAIL_OUT "can't even create an object!";

try_forcing $defer, "foo",  "new object";
is_defer $defer,            "forcing doesn't affect the object";

$targ = "bar";
is $defer->force, "bar",    "forcing is deferred";
is "$defer", "bar",         "stringify is deferred";

for (
    ['$defer->concat("B")',                 "%B"    ],
    ['$defer->concat("A", 1)',              "A%"    ],
    ['$defer->concat("B")->concat("A", 1)', "A%B"   ],

    ['$defer . "B"',                        "%B"    ],
    ['"A" . $defer',                        "A%"    ],
    ['"A" . $defer . "B"',                  "A%B"   ],

    ['"$defer B"',                          "% B"   ],
    ['"A $defer"',                          "A %"   ],
    ['"A $defer B"',                        "A % B" ],
) {
    my ($what, $pat) = @$_;

    $targ = "foo";
    my $str = eval $what;

    ok defined $str,            "$what succeeds";
    is_defer $str,              "$what returns an object";
    is "$defer", "foo",         "$what doesn't affect the original";

    (my $want = $pat) =~ s/%/foo/g;
    try_forcing $str, $want,    $what;

    $targ = "bar";
    ($want = $pat) =~ s/%/bar/g;
    try_forcing $str, $want,    "deferred $what";
}

done_testing;
