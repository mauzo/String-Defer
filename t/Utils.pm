package t::Utils;

use warnings;
use strict;

use Test::More;
use Exporter;
our @ISA = "Exporter";
our @EXPORT = (
    @Test::More::EXPORT,
    qw/is_defer is_plain try_forcing/,
);

sub is_defer {
    my ($obj, $name) = @_;
    my $B = Test::More->builder;
    $B->ok(eval { $obj->isa("String::Defer") }, $name);
}

sub is_plain {
    my ($str, $name) = @_;
    my $B = Test::More->builder;
    $B->ok(!ref $str, $name);
}

sub try_forcing {
    my ($obj, $want, $name) = @_;
    my $B = Test::More->builder;

    for (
        [ forced        => eval { $obj->force } ],
        [ stringified   => eval { "$obj" }      ],
    ) {
        my ($what, $str) = @$_;
        $B->ok(defined $str,    "$name can be $what");
        $B->ok(!ref $str,       "$name $what gives a plain string");
        $B->is_eq($str, $want,  "$name $what gives correct contents");
    }
}
