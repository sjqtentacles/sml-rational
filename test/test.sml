(* Dependency-free test runner for the Rational structure.
 * Prints one line per assertion and exits non-zero if any assertion fails. *)

structure Tests =
struct

structure R = Rational

val check = Harness.check

(* True iff `thunk ()` raises General.Div. *)
fun raisesDiv (thunk : unit -> 'a) : bool =
    (ignore (thunk ()); false) handle General.Div => true | _ => false

val i = IntInf.fromInt

fun run () =
  let
    (* Construction and toString *)
    val () = check "zero prints 0" (R.toString R.zero = "0")
    val () = check "one prints 1" (R.toString R.one = "1")
    val () = check "fromInt 5 prints 5" (R.toString (R.fromInt 5) = "5")
    val () = check "fromInt ~3 prints -3" (R.toString (R.fromInt ~3) = "-3")
    val () = check "fromFrac 3/4 prints 3/4" (R.toString (R.fromFrac (i 3, i 4)) = "3/4")

    (* Normalization: reduction to lowest terms *)
    val () = check "6/8 reduces to 3/4" (R.toString (R.fromFrac (i 6, i 8)) = "3/4")
    val () = check "10/2 reduces to 5" (R.toString (R.fromFrac (i 10, i 2)) = "5")
    val () = check "0/5 normalizes to 0" (R.toString (R.fromFrac (i 0, i 5)) = "0")

    (* Sign normalization: denominator always positive *)
    val () = check "6/-8 normalizes to -3/4" (R.toString (R.fromFrac (i 6, i ~8)) = "-3/4")
    val () = check "-6/-8 normalizes to 3/4" (R.toString (R.fromFrac (i ~6, i ~8)) = "3/4")
    val () = check "denominator of 6/-8 is positive 4"
                   (R.denominator (R.fromFrac (i 6, i ~8)) = i 4)
    val () = check "numerator of 6/-8 is -3"
                   (R.numerator (R.fromFrac (i 6, i ~8)) = i ~3)

    (* Accessors on a reduced value *)
    val () = check "numerator 3/4 = 3" (R.numerator (R.fromFrac (i 3, i 4)) = i 3)
    val () = check "denominator 3/4 = 4" (R.denominator (R.fromFrac (i 3, i 4)) = i 4)

    (* Arithmetic *)
    val half = R.fromFrac (i 1, i 2)
    val third = R.fromFrac (i 1, i 3)
    val () = check "1/2 + 1/3 = 5/6" (R.toString (R.+ (half, third)) = "5/6")
    val () = check "1/2 - 1/3 = 1/6" (R.toString (R.- (half, third)) = "1/6")
    val () = check "1/2 * 1/3 = 1/6" (R.toString (R.* (half, third)) = "1/6")
    val () = check "1/2 div 1/3 = 3/2" (R.toString (R.div (half, third)) = "3/2")
    val () = check "1/2 + 1/2 = 1" (R.toString (R.+ (half, half)) = "1")
    val () = check "2/3 * 3/2 = 1" (R.toString (R.* (R.fromFrac (i 2, i 3), R.fromFrac (i 3, i 2))) = "1")
    val () = check "negate 3/4 = -3/4" (R.toString (R.~ (R.fromFrac (i 3, i 4))) = "-3/4")
    val () = check "negate -3/4 = 3/4" (R.toString (R.~ (R.fromFrac (i ~3, i 4))) = "3/4")
    val () = check "inv 3/4 = 4/3" (R.toString (R.inv (R.fromFrac (i 3, i 4))) = "4/3")
    val () = check "inv -3/4 = -4/3" (R.toString (R.inv (R.fromFrac (i ~3, i 4))) = "-4/3")

    (* Comparison and equality *)
    val () = check "1/2 = 2/4" (R.equal (half, R.fromFrac (i 2, i 4)))
    val () = check "1/2 <> 1/3" (not (R.equal (half, third)))
    val () = check "compare 1/3 1/2 = LESS" (R.compare (third, half) = LESS)
    val () = check "compare 1/2 1/3 = GREATER" (R.compare (half, third) = GREATER)
    val () = check "compare 1/2 2/4 = EQUAL" (R.compare (half, R.fromFrac (i 2, i 4)) = EQUAL)
    val () = check "compare -1/2 1/2 = LESS"
                   (R.compare (R.fromFrac (i ~1, i 2), half) = LESS)

    (* toReal *)
    val () = check "toReal 1/2 = 0.5" (Real.== (R.toReal half, 0.5))
    val () = check "toReal -3/4 = -0.75" (Real.== (R.toReal (R.fromFrac (i 3, i ~4)), ~0.75))

    (* fromString *)
    val () = check "fromString \"3/4\"" (R.toString (valOf (R.fromString "3/4")) = "3/4")
    val () = check "fromString \"5\"" (R.toString (valOf (R.fromString "5")) = "5")
    val () = check "fromString \"-5\"" (R.toString (valOf (R.fromString "-5")) = "-5")
    val () = check "fromString \"6/-8\" = -3/4" (R.toString (valOf (R.fromString "6/-8")) = "-3/4")
    val () = check "fromString \"6/8\" reduces" (R.toString (valOf (R.fromString "6/8")) = "3/4")
    val () = check "fromString \"\" is NONE" (not (isSome (R.fromString "")))
    val () = check "fromString \"abc\" is NONE" (not (isSome (R.fromString "abc")))
    val () = check "fromString \"1/2/3\" is NONE" (not (isSome (R.fromString "1/2/3")))
    val () = check "fromString \"3/\" is NONE" (not (isSome (R.fromString "3/")))

    (* Zero-denominator and division-by-zero error behavior *)
    val () = check "fromFrac n/0 raises Div" (raisesDiv (fn () => R.fromFrac (i 1, i 0)))
    val () = check "div by zero raises Div" (raisesDiv (fn () => R.div (half, R.zero)))
    val () = check "inv zero raises Div" (raisesDiv (fn () => R.inv R.zero))

    (* No overflow: exact arithmetic on large integers (the core value prop) *)
    val tenPow30 = IntInf.pow (i 10, 30)
    val bigFrac = R.fromFrac (tenPow30, tenPow30 + i 1)
    val () = check "10^30/(10^30+1) survives toString"
                   (R.toString bigFrac =
                    "1000000000000000000000000000000/1000000000000000000000000000001")
    val tenPow20 = R.fromFrac (IntInf.pow (i 10, 20), i 1)
    val () = check "10^20 + 10^20 = 2*10^20 exactly"
                   (R.toString (R.+ (tenPow20, tenPow20)) = "200000000000000000000")

    (* Chained arithmetic *)
    val sixth = R.fromFrac (i 1, i 6)
    val () = check "1/3 + 1/6 + 1/2 = 1"
                   (R.toString (R.+ (R.+ (third, sixth), half)) = "1")

    (* Negative and zero-producing results *)
    val () = check "1/4 - 3/4 = -1/2"
                   (R.toString (R.- (R.fromFrac (i 1, i 4), R.fromFrac (i 3, i 4))) = "-1/2")
    val () = check "3/4 - 3/4 = 0"
                   (R.toString (R.- (R.fromFrac (i 3, i 4), R.fromFrac (i 3, i 4))) = "0")
    val () = check "0 * 5/7 = 0"
                   (R.toString (R.* (R.zero, R.fromFrac (i 5, i 7))) = "0")
    val () = check "negate zero = 0" (R.toString (R.~ R.zero) = "0")

    (* compare on equivalently-signed values *)
    val () = check "compare -1/2 1/-2 = EQUAL"
                   (R.compare (R.fromFrac (i ~1, i 2), R.fromFrac (i 1, i ~2)) = EQUAL)

    (* Round-trip: fromString (toString x) = x, via structural equal *)
    val roundtrips = [R.fromFrac (i 3, i 4), R.fromFrac (i ~3, i 4),
                      R.fromInt 5, R.fromInt ~7, R.zero, bigFrac]
    val () = check "round-trip toString/fromString"
                   (List.all (fn x => R.equal (valOf (R.fromString (R.toString x)), x))
                             roundtrips)

    (* Additional fromString contract cases *)
    val () = check "fromString \"6/0\" is NONE" (not (isSome (R.fromString "6/0")))
    val () = check "fromString \"~5\" parses" (R.toString (valOf (R.fromString "~5")) = "-5")
    val () = check "fromString \"+3/4\" parses" (R.toString (valOf (R.fromString "+3/4")) = "3/4")
    val () = check "fromString \"0/5\" = 0" (R.toString (valOf (R.fromString "0/5")) = "0")
    val () = check "fromString \" 3/4\" is NONE" (not (isSome (R.fromString " 3/4")))

    (* pow: integer exponent, including negative -> reciprocal *)
    val () = check "pow (3/2, 3) = 27/8" (R.toString (R.pow (R.fromFrac (i 3, i 2), 3)) = "27/8")
    val () = check "pow (2/3, -2) = 9/4" (R.toString (R.pow (R.fromFrac (i 2, i 3), ~2)) = "9/4")
    val () = check "pow (x, 0) = 1" (R.toString (R.pow (R.fromFrac (i 7, i 5), 0)) = "1")
    val () = check "pow (5, 1) = 5" (R.toString (R.pow (R.fromInt 5, 1)) = "5")
    val () = check "pow (-2/3, 3) = -8/27" (R.toString (R.pow (R.fromFrac (i ~2, i 3), 3)) = "-8/27")
    val () = check "pow (-2/3, 2) = 4/9" (R.toString (R.pow (R.fromFrac (i ~2, i 3), 2)) = "4/9")
    val () = check "pow (zero, -1) raises Div" (raisesDiv (fn () => R.pow (R.zero, ~1)))

    (* Rounding to integers *)
    val sevenHalves = R.fromFrac (i 7, i 2)
    val () = check "floor (7/2) = 3" (R.floor sevenHalves = i 3)
    val () = check "ceil (7/2) = 4" (R.ceil sevenHalves = i 4)
    val () = check "round (7/2) = 4" (R.round sevenHalves = i 4)
    val () = check "truncate (-7/2) = -3" (R.truncate (R.fromFrac (i ~7, i 2)) = i ~3)
    val () = check "floor (-7/2) = -4" (R.floor (R.fromFrac (i ~7, i 2)) = i ~4)
    val () = check "ceil (-7/2) = -3" (R.ceil (R.fromFrac (i ~7, i 2)) = i ~3)
    val () = check "floor (5) = 5" (R.floor (R.fromInt 5) = i 5)
    val () = check "ceil (5) = 5" (R.ceil (R.fromInt 5) = i 5)
    val () = check "round (5/2) ties to even 2" (R.round (R.fromFrac (i 5, i 2)) = i 2)
    val () = check "round (7/2) ties to even 4" (R.round sevenHalves = i 4)
    val () = check "round (1/3) = 0" (R.round (R.fromFrac (i 1, i 3)) = i 0)
    val () = check "round (2/3) = 1" (R.round (R.fromFrac (i 2, i 3)) = i 1)
    val () = check "round (-5/2) ties to even -2" (R.round (R.fromFrac (i ~5, i 2)) = i ~2)

    (* Exact square root for perfect squares *)
    val () = check "sqrt (9/4) = SOME 3/2"
                   (case R.sqrt (R.fromFrac (i 9, i 4)) of SOME r => R.toString r = "3/2" | NONE => false)
    val () = check "sqrt (4) = SOME 2"
                   (case R.sqrt (R.fromInt 4) of SOME r => R.toString r = "2" | NONE => false)
    val () = check "sqrt (0) = SOME 0"
                   (case R.sqrt R.zero of SOME r => R.toString r = "0" | NONE => false)
    val () = check "sqrt (2) = NONE" (not (isSome (R.sqrt (R.fromInt 2))))
    val () = check "sqrt (1/2) = NONE" (not (isSome (R.sqrt (R.fromFrac (i 1, i 2)))))
    val () = check "sqrt (-1) = NONE" (not (isSome (R.sqrt (R.fromInt ~1))))

    (* sqrtApprox: within tolerance (exact rational comparison, no floats) *)
    val approx2 = R.sqrtApprox (R.fromInt 2, 5)
    val diff2 = R.- (R.* (approx2, approx2), R.fromInt 2)
    val tol = R.fromFrac (i 1, IntInf.pow (i 10, 4))   (* 10^~4 *)
    val () = check "sqrtApprox (2, 5)^2 within 10^-4"
                   (R.compare (R.fromFrac (IntInf.abs (R.numerator diff2), R.denominator diff2), tol) = LESS)
    val () = check "sqrtApprox (2, 5) underestimates (a^2 <= 2)"
                   (R.compare (R.* (approx2, approx2), R.fromInt 2) <> GREATER)
    val () = check "sqrtApprox (9/4, 3) = 3/2 exactly"
                   (R.equal (R.sqrtApprox (R.fromFrac (i 9, i 4), 3), R.fromFrac (i 3, i 2)))
  in
    Harness.run ()
  end

end
