import
   ../std_ext,
   macros

proc impl_is_literal(n: NimNode): bool =
   case n.kind:
   of nnk_literals:
      result = true
   else:
      result = false

macro is_literal(n: untyped): bool =
   result = gen_lit(impl_is_literal(n))

template assert_eq_str(expr, val): string =
   when is_literal(expr):
      ast_to_str(expr)
   else:
      "(" & ast_to_str(expr) & ": " & $val & ")"

template assert_eq*(a, b) =
   ## An equality assertion with a nicer message on failure.
   let a_val = a
   let b_val = b
   if a_val != b_val:
      echo("Assertion failed: ", assert_eq_str(a, a_val), " == ",
           assert_eq_str(b, b_val))
      quit(QuitFailure)

macro asserts*(stmts: untyped): untyped =
   result = gen_stmts()
   for stmt in stmts:
      result.add(gen_call("do_assert", stmt))

when defined(c) or defined(cpp):
   from c_ffi import emit

   proc black_box*[T](value: T) {.inline.} =
      ## Prevent compiler from optimizing away expression.
      emit("""asm volatile("" : : "r,m"(""", value, """) : "memory");""")
