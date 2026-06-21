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
