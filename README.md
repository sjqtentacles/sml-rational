# sml-rational

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

## Usage

### MLton

Include the library's `.mlb` from your own `.mlb`:

```
$(SML_LIB)/basis/basis.mlb
path/to/sml-rational/rational.mlb
your-code.sml
```

### Poly/ML

```sml
use "rational.sig";
use "rational.sml";
```

## Building and testing

The test suite is a dependency-free assertion runner (pure Standard ML) that
exits non-zero if any assertion fails.

```sh
# Type-check the library in isolation
mlton -stop tc rational.mlb

# Build and run the tests
mlton test/test.mlb && ./test/test
```

This library was built test-first (TDD): the signature and the full test suite
were written first against a stub implementation, the suite was confirmed to
compile and fail (red), and the implementation was then filled in until every
assertion passed (green).

## Layout

```
rational.sig    the RATIONAL signature (the contract)
rational.sml    structure Rational :> RATIONAL
rational.mlb    MLton basis file for consumers
test/test.sml   assertion-based test suite
test/test.mlb   MLton basis file for the tests
```

## License

MIT. See [LICENSE](LICENSE).
