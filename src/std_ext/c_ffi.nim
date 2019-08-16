import
  ../std_ext,
  ./macros,
  ./os

type
  CError* = object of CatchableError

macro emit*(emits: varargs[untyped]): untyped =
  result = nnk_bracket.tree()
  if emits.kind == nnk_arg_list:
    for emit in emits:
      result.add(emit)
  else:
    unexp_node(emits)
  result =
    nnk_pragma.tree(
      nnk_expr_colon_expr.tree(
        id"emit",
        result))

when defined(cpp):
  type SizeOfT = c_size
else:
  type SizeOfT = c_int

proc c_size_of*[T](val: T): usize =
  var size: SizeOfT
  emit(size, " = sizeof(", val, ");")
  result = size.usize

proc c_size_of*(T: typedesc): usize =
  var size: SizeOfT
  emit(size, " = sizeof(", default(T), ");")
  result = size.usize

macro ptr_tmps*(call: untyped): untyped =
  call.needs_kind(nnk_call_kinds)
  var tmp_vars: seq[Node]
  var set_locs: seq[Node]
  for i in span(call):
    if call[i].kind == nnk_infix and `id==`(call[i][0], ":="):
      let sym = gen_sym(nsk_var, "ptr_tmp" & $tmp_vars.len)
      tmp_vars.add(gen_def_typ(sym, call[i][1]))
      set_locs.add(gen_asgn(call[i][2],
                            gen_call(gen_call("type_of", call[i][2]), sym)))
      call[i] = nnk_addr.init(sym)
  let call_tmp_sym = gen_sym(nsk_var, "call_tmp")
  result = gen_blk_stmts(
    @[nnk_var_section.init(tmp_vars & gen_def_val(call_tmp_sym, call))] &
    set_locs &
    call_tmp_sym)
