import
   ./types,
   ../../macros

proc impl_unroll[T](n: NimNode, x_sym: NimNode, x: T): NimNode =
   result = n
   if `id==`(n, x_sym):
      result = new_lit(x)
   for i in 0 ..< n.len:
      n[i] = n[i].impl_unroll(x_sym, x)

template templ_unroll(TIter, T, iter) {.dirty.} =
   macro unroll*(x_sym: untyped, xs: static TIter, body: untyped): untyped =
      result = nnk_stmt_list.tree()
      for x in iter:
         result.add(gen_block(impl_unroll[T](copy(body), x_sym, x)))
   macro unroll_dirty*(x_sym: untyped, xs: static TIter, body: untyped): untyped =
      result = nnk_stmt_list.tree()
      for x in iter:
         result.add(impl_unroll[T](copy(body), x_sym, x))

templ_unroll(isize, isize, 0 ..< xs)
templ_unroll(openarray[isize], isize, xs)
templ_unroll(openarray[string], string, xs)

macro block_of*(op, stmts: untyped): untyped =
   stmts.needs_kind(nnk_stmt_list)
   for i in 0 ..< stmts.len:
      stmts[i] = nnk_call.tree(op, stmts[i])
   result = stmts

macro visits*(entry: untyped, stmts: untyped): untyped =
   entry.needs_kind(nnk_infix)
   entry[0].needs_id(":=")
   entry[1].needs_kind(nnk_ident)
   let to_visit_id = gen_sym(nsk_var, "to_visit")
   let cur_id = entry[1]
   let init = entry[2]
   result = quote do:
      var `to_visit_id` = @[`init`]
      template visit(elem) =
         `to_visit_id`.add(elem)
      while `to_visit_id`.len() > 0:
         var `cur_id` = `to_visit_id`.pop()
         `stmts`
