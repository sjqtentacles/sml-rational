(* demo.sml - exact rational arithmetic on fixed fractions. Every value is an
   exact fraction printed as "num/den" (or an integer) via Rational.toString,
   so the output is identical on every run and on both compilers. No reals are
   ever printed. *)

structure R = Rational

fun frac (n, d) = R.fromFrac (IntInf.fromInt n, IntInf.fromInt d)

val a = frac (1, 2)
val b = frac (1, 3)

val () = print ("a = " ^ R.toString a ^ ", b = " ^ R.toString b ^ "\n")
val () = print ("a + b   = " ^ R.toString (R.+ (a, b)) ^ "\n")
val () = print ("a - b   = " ^ R.toString (R.- (a, b)) ^ "\n")
val () = print ("a * b   = " ^ R.toString (R.* (a, b)) ^ "\n")
val () = print ("a / b   = " ^ R.toString (R.div (a, b)) ^ "\n")
val () = print ("(2/3)^~2= " ^ R.toString (R.pow (frac (2, 3), ~2)) ^ "\n")

val () =
  print ("sqrt(9/4) = "
         ^ (case R.sqrt (frac (9, 4)) of
                SOME r => R.toString r
              | NONE   => "<none>")
         ^ "\n")

val () = print ("sqrtApprox(2, 6) = " ^ R.toString (R.sqrtApprox (frac (2, 1), 6)) ^ "\n")

val () =
  print ("fromString \"6/-8\" = "
         ^ (case R.fromString "6/-8" of
                SOME r => R.toString r
              | NONE   => "<malformed>")
         ^ "\n")
