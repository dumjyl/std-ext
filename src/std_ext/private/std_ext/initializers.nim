import
  ../../macros

macro inits*(fn: untyped): untyped =
  fn[3].insert(1, gen_def_typ(id"Self", nnk_bracket_expr.init(id"typedesc",
                                                              copy(fn[3][0]))))
  result = fn

macro inits*(T: untyped, fn: untyped): untyped =
  if fn[3][0].kind == nnk_empty:
    warning("infererd return type for {.inits.} is deprecated", fn)
    fn[3][0] = copy(T)
  fn[3].insert(1, gen_def_typ(id"Self", nnk_bracket_expr.init(id"typedesc", T)))
  result = fn

proc init*(len: Natural = 0.Natural): string {.inits, inline.} =
  result = new_String(len)

proc of_cap*(cap: Natural): string {.inits, inline.} =
  result = new_String_of_cap(cap)

proc init*[T](len: Natural = 0.Natural): seq[T] {.inits, inline.} =
  result = new_Seq[T](len)

proc of_cap*[T](cap: Natural): seq[T] {.inits, inline.} =
  result = new_Seq_of_cap[T](cap)
