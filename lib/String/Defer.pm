package String::Defer;

use warnings;
use strict; 
no warnings "uninitialized"; # SHUT UP

our $VERSION = "1";

use overload        (
    q/""/       => "force",
    q/./        => "concat",
    fallback    => 1, # Why is this not the default?
);
use Exporter "import";
our @EXPORT_OK = qw/djoin/;

use Carp;
use Scalar::Util    qw/reftype blessed/;
# This list is a little bizarre, but so is the list of things
# that can legitimately be stuffed into a scalar variable. If
# BIND ever sees the light of day this will need revisiting.
my %reftypes = map +($_, 1), (
    "CODE",     # ->new(sub { })
    "SCALAR",   # my $x;            ->new(\$x)
    "VSTRING",  # my $x = v1;       ->new(\$x)
    "REF",      # my $x = \1;       ->new(\$x)
    "REGEXP",   # my $x = ${qr/x/}; ->new(\$x)

    # This should be considered experimental. It may be more beneficial
    # to treat a globref as a filehandle. I don't know if there's any
    # way to distinguish between    my $x = *STDIN; \$x
    # and either of                 \*STDIN
    #                               open my $x, ...; $x
    # I suspect SvREADONLY (on ref and on referent) would be a good
    # heuristic, if I can get at it from Perl.
    "GLOB",     # my $x = *STDIN;   ->new(\$x)
    "LVALUE",   # my $x = "foo";    ->new(\substr($x, 0, 2))
                # This will track that substring of the variable as it
                # changes, which is pretty nifty.
);

sub new {
    my ($class, $val) = @_;
    # XXX What about objects with ${}/&{} overload? Objects pretending
    # to be strings can be passed by (double) ref, and will be allowed
    # by the REF entry, but not objects pretending to be references.
    ref $val and not blessed $val and $reftypes{reftype $val}
        or croak "I need a SCALAR or CODE ref, not " .
            (blessed $val ? "an object" : reftype $val);
    bless [$val], $class;
}

# This will force a stringify now, which is what happens with a
# normal concat. I don't think allowing other random stringifyable
# objects to be deferred (when the user hasn't explicitly asked for it)
# is going to be helpful.
sub _expand { eval { $_[0]->isa(__PACKAGE__) } ? @{$_[0]} : "$_[0]" }

sub concat {
    my ($self, $str, $reverse) = @_;
    {   local $" = "|"; no overloading;
        carp "CONCAT: [@$self] [$str] $reverse";
    }
    my $class = Scalar::Util::blessed $self
        or croak "String::Defer->concat is an object method";

    my @str = _expand $str;
    bless [
        grep ref || length,
            ($reverse ? (@str, @$self) : (@$self, @str))
    ], $class;
}

sub force {
    my ($self) = @_;
    {   local $" = "|"; no overloading;
        carp "FORCE: [@$self]";
    }
    join "", map +(
        ref $_ 
            # Any objects should have been rejected or stringified by
            # this point (but see XXX above)
            ? reftype $_ eq "CODE"
                ? $_->() 
                : $$_
            : $_
    ), @$self;
}

# Join without forcing. The other string ops might be useful, and could
# certainly be implemented with closures, but would be substantially
# more complicated.
sub join {
    my ($class, $with, @strs) = @_;

    # This is a class method (a constructor, in fact), to allow
    # subclasses later, but the implementation may need adjusting. I
    # probably shouldn't be poking in the objects' guts directly, and
    # using a ->pieces method or something instead. 
    # OTOH, @{} => "pieces" would Just Work...
    ref $class and croak "String::Defer->join is a class method";

    {   local $" = "|"; no overloading;
        carp "JOIN: [$with] [@strs] -> [$class]";
    }

    # This could be optimised, but stick with the simple implementation
    # for now.
    my @with = _expand $with;
    my @last = @strs ? _expand(pop @strs) : ();
    bless [
        grep ref || length,
        (map { (_expand($_), @with) } @strs),
        @last,
    ], $class;
}

# Utility sub since C<String::Defer->join()> is rather a mouthful. This
# always creates a String::Defer, rather than a subclass.
sub djoin { __PACKAGE__->join(@_) }

1;
