import
   ./types,
   ../../macros

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
      result = nnk_stmt_list.tree()
      for x in iter:
         result.add(gen_block(impl_unroll[T](copy(body), x_sym, x)))
   macro unroll_dirty*(
         x_sym: untyped,
         xs: TIter,
         body: untyped
         ): untyped =
      result = nnk_stmt_list.tree()
      for x in iter:
         result.add(impl_unroll[T](copy(body), x_sym, x))

templ_unroll(static isize, isize, 0 ..< xs)
templ_unroll(static openarray[isize], isize, xs)
templ_unroll(static openarray[string], string, xs)
templ_unroll(openarray[typedesc], NimNode, xs)
templ_unroll(untyped, NimNode, xs)

macro make_call*(call: untyped, args: varargs[untyped]): untyped =
   result = gen_call(call)
   for arg in args:
      if arg.kind == nnk_arg_list:
         for splat_arg in arg:
            result.add(splat_arg)
      elif arg.kind == nnk_call and `id==`(arg[0], "splat"):
         for splat_arg in arg[1]:
            result.add(splat_arg)
      else:
         result.add(arg)

macro concat_args*(
      arg_a: typed,
      arg_b: typed,
      kind: static[NodeKind] = nnk_arg_list
      ): untyped =
   result = kind.init()
   template impls(args: untyped) =
      if args.kind in {nnk_bracket, nnk_arg_list}:
         for arg in args:
            result.add(arg)
      else:
         result.add(args)
   impls(arg_a)
   impls(arg_b)

macro block_of*(op, stmts: untyped): untyped =
   stmts.needs_kind(nnk_stmt_list)
   for i in 0 ..< stmts.len:
      stmts[i] = nnk_call.tree(op, stmts[i])
   result = stmts

macro visits*(entry: untyped, stmts: untyped): untyped =
   entry.needs_kind(nnk_infix)
   entry[0].needs_id(":=")
   entry[1].needs_kind(nnk_ident)
   let to_visit_id = nsk_var.init("to_visit")
   let cur_id = entry[1]
   let init = entry[2]
   result = quote do:
      var `to_visit_id` = @[`init`]
      template visit(elem: type_of(`init`)) =
         `to_visit_id`.add(elem)
      template visit(elems: varargs[type_of(`init`)]) =
         `to_visit_id`.add(elems)
      while `to_visit_id`.len() > 0:
         var `cur_id` = `to_visit_id`.pop()
         `stmts`
