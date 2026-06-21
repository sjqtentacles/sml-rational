# sml-rational

[![CI](https://github.com/sjqtentacles/sml-rational/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-rational/actions/workflows/ci.yml)

Exact rational-number arithmetic for Standard ML.

`sml-rational` provides a `Rational` structure: a `Q`-style fraction type built
on the Basis Library's arbitrary-precision integers (`IntInf`). Values are kept
in canonical form (denominator always positive, reduced to lowest terms), so
arithmetic is exact and overflow-free, and equal rationals share an identical
representation.

The Standard ML Basis Library has no built-in rational type, so this fills a
real gap. The library is **pure Standard ML (Basis-only)**, so it is portable
across compilers; it is tested on **MLton** and **Poly/ML**.

## Why

OCaml has Zarith's `Q`; SML has had nothing comparable. If you need to compute
with exact fractions (no floating-point drift), this is a small, dependency-free
library that does just that and is pleasant to read at the call site:

```sml
val r = Rational.+ (Rational.fromFrac (1, 2), Rational.fromFrac (1, 3))
val () = print (Rational.toString r ^ "\n")   (* prints "5/6" *)
```

## Signature

```sml
signature RATIONAL =
sig
  type rational
  type t = rational

  val zero : t
  val one  : t

  val fromInt    : int -> t
  val fromIntInf : IntInf.int -> t
  val fromFrac   : IntInf.int * IntInf.int -> t   (* num, den; raises General.Div if den = 0 *)
  val fromString : string -> t option             (* "3/4", "-5", "~5", "6/-8" *)

  val numerator   : t -> IntInf.int
  val denominator : t -> IntInf.int

  val ~   : t -> t
  val +   : t * t -> t
  val -   : t * t -> t
  val *   : t * t -> t
  val div : t * t -> t                            (* raises General.Div on a zero divisor *)

  val inv : t -> t                                (* reciprocal; raises General.Div on zero *)

  val compare : t * t -> order
  val equal   : t * t -> bool

  val toReal   : t -> real
  val toString : t -> string                      (* "3/4", or "5" when integral *)
end
```

### Notes

- **Canonical form.** Every value satisfies `denominator > 0` and
  `gcd(|numerator|, denominator) = 1`. `0` is represented as `0/1`.
- **`toReal` is an approximation.** Rationals are exact, but `real` is not, so
  `toReal` returns the nearest floating-point value, not an exact result.
- **Error handling.** Constructing a fraction with a zero denominator, dividing
  by a zero rational, or taking the reciprocal of zero raises `General.Div`.
  `fromString` returns `NONE` for malformed input (including a zero denominator).
- **`toString` / `fromString`.** Output uses a conventional minus sign
  (`-3/4`), not SML's tilde, and an integral value prints without a denominator
  (`5`, not `5/1`). `fromString` accepts either `-` or `~` as the sign.

## Installing with smlpkg

This library follows the conventions of the
[`smlpkg`](https://github.com/diku-dk/smlpkg) package manager. There is no
registry or account to sign up for -- packages are referenced directly by
their git URL. In your own project's directory:

```sh
smlpkg add github.com/sjqtentacles/sml-rational
smlpkg sync
```

This downloads the library into
`lib/github.com/sjqtentacles/sml-rational/`. Reference its `.mlb` from your
own `.mlb` with a relative path.

## Usage

### MLton

Include the library's `.mlb` from your own `.mlb`:

```
$(SML_LIB)/basis/basis.mlb
lib/github.com/sjqtentacles/sml-rational/rational.mlb
your-code.sml
```

### Poly/ML

```sml
use "lib/github.com/sjqtentacles/sml-rational/rational.sig";
use "lib/github.com/sjqtentacles/sml-rational/rational.sml";
```

## Building and testing

The test suite is a dependency-free assertion runner (pure Standard ML) that
exits non-zero if any assertion fails.

```sh
make test        # build + run the suite under MLton
make test-poly   # run the suite under Poly/ML
make all-tests   # run under both
make clean
```

This library was built test-first (TDD): the signature and the full test suite
were written first against a stub implementation, the suite was confirmed to
compile and fail (red), and the implementation was then filled in until every
assertion passed (green).

## Layout

```
sml.pkg                 smlpkg manifest (package name + requires)
lib/github.com/sjqtentacles/sml-rational/
  rational.sig          the RATIONAL signature (the contract)
  rational.sml          structure Rational :> RATIONAL
  rational.mlb          MLton basis file for consumers
test/test.sml           assertion-based test suite
test/test.mlb           MLton basis file for the tests
Makefile                build + test (MLton and Poly/ML)
.github/workflows/ci.yml  CI on both compilers
```

## License

MIT. See [LICENSE](LICENSE).
