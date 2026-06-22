structure Rational :> RATIONAL =
struct
  (* Canonical form invariant: den > 0 and gcd(|num|, den) = 1.
   * Zero is represented as (0, 1). *)
  type rational = IntInf.int * IntInf.int
  type t = rational

  val zeroI : IntInf.int = 0
  val oneI  : IntInf.int = 1

  (* Euclid's algorithm; the Basis has no IntInf.gcd. Result is non-negative
   * for non-negative inputs (we only ever call it with |num| and den > 0). *)
  fun gcd (a : IntInf.int, b : IntInf.int) : IntInf.int =
      if b = zeroI then a else gcd (b, IntInf.mod (a, b))

  (* Floor of the integer square root via Newton's method on IntInf (no Real,
   * so it is exact and deterministic). For n >= 0 returns the largest r with
   * r*r <= n. The initial guess 2^(ceil(bits/2)) is >= sqrt n, from which the
   * Newton iteration decreases monotonically to the floor. *)
  fun isqrt (n : IntInf.int) : IntInf.int =
      if n < zeroI then raise General.Div
      else if n < (2 : IntInf.int) then n
      else
        let
          fun bits (k, acc) = if k = zeroI then acc else bits (IntInf.div (k, 2), acc + 1)
          val b = bits (n, 0)
          val g0 = IntInf.<< (oneI, Word.fromInt ((b + 1) div 2))
          fun iter x =
              let val y = IntInf.div (IntInf.+ (x, IntInf.div (n, x)), 2)
              in if y >= x then x else iter y end
        in
          iter g0
        end

  (* Smart constructor: enforce the canonical form. Raises General.Div when
   * the denominator is zero. *)
  fun make (n : IntInf.int, d : IntInf.int) : t =
      if d = zeroI then raise General.Div
      else
        let
          (* Push the sign onto the numerator so the denominator is positive. *)
          val (n, d) = if d < zeroI then (IntInf.~ n, IntInf.~ d) else (n, d)
          val g = gcd (IntInf.abs n, d)
          val g = if g = zeroI then oneI else g
        in
          (IntInf.div (n, g), IntInf.div (d, g))
        end

  val zero : t = (zeroI, oneI)
  val one  : t = (oneI, oneI)

  fun fromIntInf n = (n, oneI)
  fun fromInt i = (IntInf.fromInt i, oneI)
  fun fromFrac (n, d) = make (n, d)

  fun numerator (n, _) = n
  fun denominator (_, d) = d

  fun op ~ (n, d) = (IntInf.~ n, d)

  fun op + ((a, b), (c, d)) =
      make (IntInf.+ (IntInf.* (a, d), IntInf.* (c, b)), IntInf.* (b, d))

  fun op - ((a, b), (c, d)) =
      make (IntInf.- (IntInf.* (a, d), IntInf.* (c, b)), IntInf.* (b, d))

  fun op * ((a, b), (c, d)) =
      make (IntInf.* (a, c), IntInf.* (b, d))

  fun inv (n, d) = make (d, n)   (* make raises General.Div when n = 0 *)

  fun op div (x, y) = op * (x, inv y)

  (* Integer power. A reduced fraction raised to a non-negative power stays
   * reduced and keeps a positive denominator, so the result is canonical. A
   * negative exponent takes the reciprocal of the positive power. *)
  fun pow ((n, d) : t, e : int) : t =
      if e = 0 then one
      else if e < 0 then inv (pow ((n, d), Int.~ e))
      else (IntInf.pow (n, e), IntInf.pow (d, e))

  (* SML's IntInf.div truncates toward negative infinity, which is exactly the
   * floor of n/d for a positive denominator. *)
  fun floor ((n, d) : t) : IntInf.int = IntInf.div (n, d)

  fun ceil (x : t) : IntInf.int = IntInf.~ (floor (op ~ x))

  (* Toward zero: IntInf.quot truncates toward zero. *)
  fun truncate ((n, d) : t) : IntInf.int = IntInf.quot (n, d)

  (* Nearest integer, ties to even. With q = floor x and remainder rem = n - q*d
   * in [0, d), compare 2*rem to d: below rounds down, above rounds up, and an
   * exact half rounds to whichever of q / q+1 is even. *)
  fun round ((n, d) : t) : IntInf.int =
      let
        val q = IntInf.div (n, d)
        val rem = IntInf.- (n, IntInf.* (q, d))
        val twice = IntInf.* (2, rem)
      in
        case IntInf.compare (twice, d) of
            LESS    => q
          | GREATER => IntInf.+ (q, oneI)
          | EQUAL   => if IntInf.mod (q, 2) = zeroI then q else IntInf.+ (q, oneI)
      end

  (* Exact square root for perfect squares. A reduced n/d (d > 0) is a perfect
   * square iff n and d are both perfect squares, since gcd(n, d) = 1. *)
  fun sqrt ((n, d) : t) : t option =
      if n < zeroI then NONE
      else
        let
          val rn = isqrt n
          val rd = isqrt d
        in
          if IntInf.* (rn, rn) = n andalso IntInf.* (rd, rd) = d
          then SOME (rn, rd)
          else NONE
        end

  (* Decimal-digit rational approximation: floor (x * 10^(2*digits)) integer
   * square root, over 10^digits. *)
  fun sqrtApprox ((n, d) : t, digits : int) : t =
      if n < zeroI then raise General.Div
      else
        let
          val scale = IntInf.pow (10, digits)        (* 10^digits *)
          val scaledNum = IntInf.* (n, IntInf.* (scale, scale))   (* n * 10^(2*digits) *)
          val a = isqrt (IntInf.div (scaledNum, d))
        in
          make (a, scale)
        end

  (* Both are canonical with positive denominators, so cross-multiplication
   * preserves sign and order. *)
  fun compare ((a, b), (c, d)) = IntInf.compare (IntInf.* (a, d), IntInf.* (c, b))

  (* Canonical form makes equal rationals structurally identical, so we can
   * compare the pairs directly rather than cross-multiplying via compare. *)
  fun equal ((a, b) : t, (c, d) : t) = a = c andalso b = d

  (* IntInf.toString uses a leading tilde for negatives; emit a conventional
   * minus sign instead so output is portable and human-friendly. *)
  fun intInfToString (v : IntInf.int) : string =
      if v < zeroI then "-" ^ IntInf.toString (IntInf.~ v)
      else IntInf.toString v

  fun toReal (n, d) = Real.fromLargeInt n / Real.fromLargeInt d

  fun toString (n, d) =
      if d = oneI then intInfToString n
      else intInfToString n ^ "/" ^ intInfToString d

  (* Parse an optionally-signed decimal integer; NONE on any extra characters.
   * Accepts both '-' and SML's '~' as the negative sign. *)
  fun parseInt (s : string) : IntInf.int option =
      if s = "" then NONE
      else
        let
          val c0 = String.sub (s, 0)
          val (neg, body) =
              if c0 = #"-" orelse c0 = #"~" then (true, String.extract (s, 1, NONE))
              else if c0 = #"+" then (false, String.extract (s, 1, NONE))
              else (false, s)
        in
          if body = "" orelse not (CharVector.all Char.isDigit body) then NONE
          else case IntInf.fromString body of
                   NONE => NONE
                 | SOME v => SOME (if neg then IntInf.~ v else v)
        end

  fun fromString (s : string) : t option =
      case String.fields (fn c => c = #"/") s of
          [whole] => Option.map fromIntInf (parseInt whole)
        | [n, d] =>
            (case (parseInt n, parseInt d) of
                 (SOME n, SOME d) => (SOME (make (n, d)) handle General.Div => NONE)
               | _ => NONE)
        | _ => NONE
end
