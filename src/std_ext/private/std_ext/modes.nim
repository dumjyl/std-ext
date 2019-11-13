template main*(stmts: untyped) =
   when is_main_module:
      stmts

template main_proc*(stmts: untyped) =
   main:
      proc impl_main_proc {.gen_sym.} =
         stmts
      impl_main_proc()

template test*(stmts: untyped) =
   when is_main_module and defined(testing):
      stmts

template test_proc*(stmts: untyped) =
   test:
      proc impl_test_proc {.gen_sym.} =
         stmts
      impl_test_proc()

template debug*(body: untyped): untyped =
   when not defined(release):
      body

from std/strutils import cmp_ignore_style
export cmp_ignore_style

template `aststr~=`*(ast_a, ast_b: untyped): bool =
   cmp_ignore_style(ast_to_str(ast_a), ast_to_str(ast_b)) != 0

template mode_condition*(condition: untyped): bool =
   when condition is bool:
      condition
   else:
      when `aststr~=`(condition, main) or `aststr~=`(condition, app) or
           `aststr~=`(condition, application):
         is_main_module
      elif `aststr~=`(condition, test):
         defined(testing)
      else:
         defined(condition)

template sec*(condition: untyped, stmts: untyped) =
   when mode_condition(condition):
      stmts

template run*(condition, stmts: untyped) =
   when mode_condition(condition):
      proc run_fn {.gen_sym.} =
         stmts
      run_fn()

template run*(stmts: untyped) =
   when mode_condition(main):
      proc run_fn {.gen_sym.} =
         stmts
      run_fn()

