import
   ../std_ext,
   ./macros,
   ./os

type
   CError* = object of CatchableError

macro emit*(emits: varargs[untyped]): untyped =
   ## A callable version of `{.emit.}`.
   result = nnk_bracket.init()
   if emits.kind == nnk_arg_list:
      for emit in emits:
         result.add(emit)
   else:
      unexp_err(emits)
   result =
      nnk_pragma.init(
         nnk_expr_colon_expr.init(
            id"emit",
            result))

when defined(cpp):
   type SizeOfT = c_usize
else:
   type SizeOfT = c_int

proc c_size_of*[T](val: T): usize =
   ## c/c++ sizeof, for debugging.
   var size: SizeOfT
   emit(size, " = sizeof(", val, ");")
   result = size.usize

proc c_size_of*(T: typedesc): usize =
   ## c/c++ sizeof, for debugging.
   var size: SizeOfT
   emit(size, " = sizeof(", default(T), ");")
   result = size.usize

macro ptr_tmps*(call: untyped): untyped =
   call.needs_kind(nnk_call_kinds)
   var tmp_vars: seq[Node]
   var set_locs: seq[Node]
   for i in span(call):
      if call[i].kind == nnk_infix and `id==`(call[i][0], ":="):
         let sym = nsk_var.init("ptr_tmp" & $tmp_vars.len)
         tmp_vars.add(gen_def_typ(sym, call[i][1]))
         set_locs.add(gen_asgn(call[i][2],
                               gen_call(gen_call("type_of", call[i][2]), sym)))
         call[i] = nnk_addr.init(sym)
   let call_tmp_sym = nsk_var.init("call_tmp")
   result = gen_block(
      nnk_stmt_list.init(
         @[nnk_var_section.init(tmp_vars & gen_def_val(call_tmp_sym, call))] &
         set_locs &
         call_tmp_sym))

macro cpp_ctor*(fn: untyped): untyped =
   ## A function pragma that creates another proc, `new` for creating a class
   ## ptr.
   var obj_fn = fn.copy
   obj_fn.add_pragma(id"constructor")
   var ptr_fn = fn.copy
   ptr_fn.name = id"new"
   for pragma in ptr_fn.pragmas:
      if pragma.kind == nnk_expr_colon_expr and `id==`(pragma[0], "import_cpp"):
         pragma[1] = gen_lit("(new " & pragma[1].str_val & ")")
         break
   result = gen_stmts(obj_fn, ptr_fn)
