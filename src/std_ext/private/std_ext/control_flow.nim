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

template main*(stmts: untyped) =
   ## Like `anon` but only for when `is_main_module`
   when is_main_module:
      proc main_fn {.gen_sym.} =
         stmts
      main_fn()

template anon*(stmts: untyped): untyped =
   proc anon_fn: auto {.gen_sym, nim_call.} = stmts
   anon_fn()

template anon_when*(condition: untyped, stmts: untyped): untyped =
   when mode_condition(condition):
      anon(stmts)

template static_anon*(stmts: untyped): untyped =
   proc static_anon_fn: auto {.gen_sym, nim_call.} = stmts
   system.static(static_anon_fn())

proc impl_unroll[T](n: NimNode, x_sym: NimNode, x: T): NimNode =
   result = n
   if `id==`(n, x_sym):
      when T is NimNode:
         result = x
      else:
         result = gen_lit(x)
   for i in 0 ..< n.len:
      n[i] = n[i].impl_unroll(x_sym, x)

template templ_unroll(TIter, T, iter) {.dirty.} =
   macro unroll*(x_sym: untyped, xs: TIter, body: untyped): untyped =
      result = nnk_stmt_list.init()
      for x in iter:
         result.add(gen_block(impl_unroll[T](copy(body), x_sym, x)))
   macro unroll_dirty*(
         x_sym: untyped,
         xs: TIter,
         body: untyped
         ): untyped =
      result = nnk_stmt_list.init()
      for x in iter:
         result.add(impl_unroll[T](copy(body), x_sym, x))

templ_unroll(static isize, isize, 0 ..< xs)
templ_unroll(static openarray[isize], isize, xs)
templ_unroll(static openarray[string], string, xs)
templ_unroll(openarray[typedesc], NimNode, xs)
templ_unroll(untyped, NimNode, xs)

macro block_of*(op, stmts: untyped): untyped =
   ## Apply `op` to every stmt in `stmts`.
   stmts.needs_kind(nnk_stmt_list)
   for i in 0 ..< stmts.len:
      stmts[i] = nnk_call.init(op, stmts[i])
   result = stmts
