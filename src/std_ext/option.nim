import
  ../std_ext,
  ./match,
  ./macros

type
  OptionError* = object of Defect
  Option*[T] = object
    when T is Nilable:
      val: T
    else:
      val: T
      has_val: bool
  ResultError* = object of Defect
  Result*[T, E] = object
    when T is Nilable:
      val: T
      err: E
    else:
      val: T
      err: E
      has_val: bool

proc init*[T](val: T): Option[T] {.inits.} =
  result.val = val
  when T is Nilable:
    debug:
      if unlikely(result.val == nil):
        OptionError.throw($Option[T] & " initialized with nil value")
  else:
    result.has_val = true

proc none*[T](): Option[T] {.inits.} =
  result = default(Option[T])

proc is_val*[T](opt: Option[T]): bool =
  when T is Nilable:
    result = opt.val != nil
  else:
    result = opt.has_val

proc is_none*[T](opt: Option[T]): bool =
  result = not opt.is_val()

proc unsafe_val*[T](opt: Option[T]): T =
  debug:
    if unlikely(opt.is_none()):
      OptionError.throw($Option[T] & " unpacking value failed")
  result = opt.val

proc unsafe_maybe_uninit_val*[T](opt: Option[T]): T =
  if opt.is_val():
    result = opt.val
  else:
    result = default(T)

template `?=`*(maybe_val: untyped, name: untyped): untyped =
  let temp_maybe_val = maybe_val
  var name = unsafe_maybe_uninit_val(maybe_val)
  temp_maybe_val.is_val()

template unwrap*[T](opt: Option[T], msg: varargs[string, `$`]): T =
  let opt_temp = opt
  if unlikely(opt_temp.is_none()):
    {.line.}:
      failure(@msg)
  opt_temp.val

proc `$`*[T](opt: Option[T]): string =
  if opt ?= val:
    result = "value(" & $val & ")"
  else:
    result = "none(" & $T & ")"

proc init*[E]: Result[Unit, E] {.inits.} =
  result.err = default(E)
  result.has_val = true

proc init*[T, E](val: sink T): Result[T, E] {.inits.} =
  result.val = val
  result.err = default(E)
  when T is Nilable:
    debug:
      if unlikely(result.val == nil):
        ResultError.throw($Result[T, E] & " initialized with nil value")
  else:
    result.has_val = true

proc err*[T, E](err: E): Result[T, E] {.inits.} =
  result.err = err

proc is_ok*[T, E](res: Result[T, E]): bool =
  when T is Nilable:
    result = res.val != nil
  else:
    result = res.has_val

proc is_err*[T, E](res: Result[T, E]): bool =
  result = not res.is_ok()

proc unsafe_val*[T, E](res: Result[T, E]): lent T =
  debug:
    if unlikely(res.is_err()):
      ResultError.throw($Result[T, E] & " unpacking value failed")
  result = res.val

proc unsafe_err*[T, E](res: Result[T, E]): lent E =
  debug:
    if unlikely(res.is_ok()):
      ResultError.throw($Result[T, E] & " unpacking error failed")
  result = res.err

proc unsafe_take_val*[T, E](res: sink Result[T, E]): T =
  debug:
    if unlikely(res.is_err()):
      ResultError.throw($Result[T, E] & " unpacking value failed")
  result = res.val

proc unsafe_take_err*[T, E](res: sink Result[T, E]): E =
  debug:
    if unlikely(res.is_ok()):
      ResultError.throw($Result[T, E] & " unpacking error failed")
  result = res.err

proc `$`*[T, E](res: Result[T, E]): string =
  if res.is_ok():
    result = "ok(" & $res.unsafe_val() & ")"
  else:
    result = "error(" & $res.unsafe_err() & ")"

macro unpack*(res: Result, branches: varargs[untyped]): untyped =
  let tmp_sym = gen_sym(nsk_var, "res_tmp")
  branches.needs_kind(nnk_arg_list)
  branches.needs_len(2)
  var if_branches: seq[Node]
  for branch in branches:
    branch.needs_kind(nnk_of_branch)
    branch[0].needs_kind(nnk_infix)
    branch[0][1].needs_kind(nnk_sym_like_kinds)
    branch[0][2].needs_id("T", "E")
    var is_ok = `id==`(branch[0][2], "T")
    if_branches.add(
      nnk_elif_branch.init(
        gen_call(if is_ok: "is_ok" else: "is_err", tmp_sym),
        stmt_concat(
          gen_var_val(
            branch[0][1],
            gen_call(
              if is_ok: "unsafe_take_val" else: "unsafe_take_err",
              tmp_sym)),
          branch[1])))
  result = stmt_concat(gen_var_val(tmp_sym, res), nnk_if_stmt.init(if_branches))
