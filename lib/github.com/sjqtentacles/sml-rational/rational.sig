(* RATIONAL: exact rational arithmetic over arbitrary-precision integers.
 *
 * A value of type `t` represents an exact fraction n/d held in canonical
 * form: the denominator is always strictly positive and gcd(|n|, d) = 1,
 * so equal rationals share an identical representation. The type is built
 * on the Basis `IntInf`, so there is no overflow.
 *
 * Functions that would divide by zero (constructing a fraction with a zero
 * denominator, or `div` by a zero rational) raise `General.Div`.
 *)
signature RATIONAL =
sig
  type rational
  type t = rational

  val zero : t
  val one  : t

  (* Construction. `fromString` accepts "n", "n/d", optional leading sign on
   * either component, where the sign may be '-' or SML's '~' (e.g. "3", "-5",
   * "~5", "3/4", "6/-8"); returns NONE on any malformed input or an explicit
   * zero denominator. *)
  val fromInt    : int -> t
  val fromIntInf : IntInf.int -> t
  val fromFrac   : IntInf.int * IntInf.int -> t   (* num, den; raises General.Div if den = 0 *)
  val fromString : string -> t option

  (* Accessors return the canonical numerator/denominator (den > 0). *)
  val numerator   : t -> IntInf.int
  val denominator : t -> IntInf.int

  val ~   : t -> t
  val +   : t * t -> t
  val -   : t * t -> t
  val *   : t * t -> t
  val div : t * t -> t                              (* raises General.Div on a zero divisor *)

  val inv : t -> t                                  (* reciprocal; raises General.Div on zero *)

  (* Integer power. The exponent is an ordinary `int`: a negative exponent
   * yields the reciprocal raised to the magnitude (e.g. pow (2/3, ~2) = 9/4).
   * pow (x, 0) = one for every x, including zero; pow (zero, e) for e < 0
   * raises General.Div (it reduces to inv zero). *)
  val pow : t * int -> t

  (* Rounding to an integer, each returning the chosen IntInf. Conventions:
   *   floor    -- largest integer <= x        (toward negative infinity)
   *   ceil     -- smallest integer >= x       (toward positive infinity)
   *   truncate -- drop the fractional part    (toward zero)
   *   round    -- nearest integer, ties to even (banker's rounding)
   * e.g. floor (7/2) = 3, ceil (7/2) = 4, truncate (~7/2) = ~3, round (7/2) = 4. *)
  val floor    : t -> IntInf.int
  val ceil     : t -> IntInf.int
  val truncate : t -> IntInf.int
  val round    : t -> IntInf.int

  (* Exact square root for perfect-square rationals: returns SOME r with r*r = x
   * when one exists (e.g. sqrt (9/4) = SOME (3/2)), and NONE otherwise
   * (non-perfect squares and every negative value). *)
  val sqrt : t -> t option

  (* Rational approximation of the (non-negative) square root accurate to the
   * given number of decimal digits: returns a/10^digits where a is the integer
   * square root of floor (x * 10^(2*digits)). `digits` should be >= 0;
   * applying it to a negative value raises General.Div. e.g. sqrtApprox (2, 5)
   * approximates sqrt 2 with |result^2 - 2| < 10^~4. *)
  val sqrtApprox : t * int -> t

  val compare : t * t -> order
  val equal   : t * t -> bool

  val toReal   : t -> real
  val toString : t -> string                        (* "3/4", or "5" when integral *)
end
