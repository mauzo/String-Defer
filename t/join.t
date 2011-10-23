#!/usr/bin/perl

use strict;
use warnings;

use t::Utils;

BEGIN {
    # XXX Test::Exports should support this idiom directly
    #
    require String::Defer;

    import_ok "String::Defer", ["djoin"],   "djoin import succeeds";
    is_import "djoin", "String::Defer",     "djoin imports correctly"
        or die "can't import djoin";

    new_import_pkg;

    import_ok "String::Defer", [],          "empty import list succeeds";
    cant_ok "djoin",                        "djoin not exported by default";

    String::Defer->import("djoin");
}

my @targ  = map \my $x, 0..2;
my @defer = map String::Defer->new($targ[$_]), 0..2;

sub settarg { ${$targ[$_]} = $_[$_] for 0..$#_ }

sub join_ok {
    my ($args, $fbb, $ott, $name) = @_;

    settarg qw/foo bar baz/;
    my $join = djoin @$args;

    is_defer $join,                 "$name gives a String::Defer";
    is "$join", $fbb,               "$name forces correctly";

    settarg qw/one two three/;
    is "$join", $ott,               "$name defers correctly";
}

join_ok @$_ for (
    [[":", @defer],         
        "foo:bar:baz",  "one:two:three",
        "join"],

    [[@defer],
        "barfoobaz",    "twoonethree",          
        "join on deferred"],

    [[":", $defer[0], "A", $defer[1], "B"],
        "foo:A:bar:B",  "one:A:two:B",
        "mixed join"],

    [[$defer[0], qw/A B C/],
        "AfooBfooC",    "AoneBoneC",
        "join of plain on deferred"],

    [[$defer[0], "A", $defer[1], "B"],
        "AfoobarfooB",  "AonetwooneB",
        "mixed join on deferred"],

    # XXX this should probably not defer the result
    [[qw/: A B C/],
        "A:B:C",        "A:B:C",
        "join of all plain strings"],
);

settarg qw/foo/;
for (
    [SCALAR         => \1                                           ],
    [VSTRING        => \v1                                          ],
    [REF            => \\1                                          ],
    ($? >= 5.010 ?
    [REGEXP         => ${qr/x/},            "".qr/x/                ]
        : () ),
    [LVALUE         => \substr(my $x, 0, 1)                         ],
    [ARRAY          => []                                           ],
    [HASH           => {}                                           ],
    [CODE           => sub { 1 }                                    ],
    [GLOB           => \*STDOUT,                                    ],
    [IO             => *STDOUT{IO},         "IO::File=IO"           ],
    [FORMAT         => *Format{FORMAT}                              ],
    ["plain object" => PlainObject->new,    "PlainObject=ARRAY"     ],
) {
    my ($type, $ref, $pat) = @$_;
    $pat ||= $type;
    my $join = djoin ":", $defer[0], $ref;
    like "$join", qr/^foo:$pat\(0x[[:xdigit:]]+\)$/,
                                "join stringifies $type refs";
}

{
    settarg qw/foo/;
    my $obj = StrOverload->new("bar");
    my $join = djoin ":", $defer[0], $obj;
    is "$join", "foo:bar",      "join with \"\"-overloaded object";

    settarg qw/one/;
    $obj->[0] = "two";
    is "$join", "one:bar",      "\"\"-object does not get deferred";
    is "$obj", "two",           "\"\"-object is unaffected by join";
}

done_testing;
