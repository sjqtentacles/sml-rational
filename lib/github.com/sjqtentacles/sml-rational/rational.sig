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

  val compare : t * t -> order
  val equal   : t * t -> bool

  val toReal   : t -> real
  val toString : t -> string                        (* "3/4", or "5" when integral *)
end
