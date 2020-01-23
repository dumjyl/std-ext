import
   ../../macros,
   types
from std/strutils import cmp_ignore_style

template loop*(label: untyped, stmts: untyped): untyped =
   ## An infinite look with label for early exit.
   runnable_examples:
      loop outer:
         for j in 1 .. 100:
            if j == 50:
               break outer
   block label:
      while true:
         stmts

template loop*(stmts: untyped): untyped =
   ## An infinite loop.
   while true:
      stmts

template `ast_str~=`(ast_a, ast_b: untyped): bool =
   cmp_ignore_style(ast_to_str(ast_a), ast_to_str(ast_b)) == 0

template mode_condition(condition: untyped): bool =
   when `ast_str~=`(condition, app) or `ast_str~=`(condition, main):
      is_main_module
   elif `ast_str~=`(condition, test):
      defined(testing)
   elif `ast_str~=`(condition, debug):
      not defined(release)
   else:
      defined(condition)

template section*(condition: untyped, stmts: untyped) =
   ## A section of code defined only upon `condition`.
   ##
   ## This condition may be:
   ## * `app`, `main` for `isMainModule`.
   ## * `test` for `-d:testing`.
   ## * `debug` for lack of `-d:release`
   ## * Some other define.
   when mode_condition(condition):
      stmts

template anon*(stmts: untyped): untyped =
   proc anon_fn: auto {.gen_sym, nim_call.} = stmts
   anon_fn()

template anon_when*(condition: untyped, stmts: untyped): untyped =
   when mode_condition(condition):
      anon(stmts)

template static_anon*(stmts: untyped): untyped =
   proc static_anon_fn: auto {.gen_sym, nim_call.} = stmts
   system.static(static_anon_fn())
