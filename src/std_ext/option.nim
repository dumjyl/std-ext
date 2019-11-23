import
   ../std_ext,
   ./macros

type
   OptError* = object of Defect
   Opt*[T] = object
      when T is Nilable:
         val: T
      else:
         val: T
         has_val: bool
   ResError* = object of Defect
   Res*[T, E] = object
      when T is Nilable:
         val: T
         err: E
      else:
         val: T
         err: E
         has_val: bool

proc init*[T](val: sink T): Opt[T] {.attach.} =
   result.val = val
   when T is Nilable:
      when_debug:
         if unlikely(result.val == nil):
            OptError.throw($Opt[T] & " initialized with nil value")
   else:
      result.has_val = true

proc some*[T](val: T): Opt[T] {.attach: T, inline.} =
   result = Opt[T].init(val)

proc some*[T](val: T): Opt[T] {.inline.} =
   result = Opt[T].init(val)

proc none*[T](): Opt[T] {.attach: T, inline.} =
   result = default(Opt[T])

proc is_val*[T](opt: Opt[T]): bool =
   when T is Nilable:
      result = opt.val != nil
   else:
      result = opt.has_val

proc is_none*[T](opt: Opt[T]): bool =
   result = not opt.is_val()

proc unsafe_val*[T](opt: Opt[T]): T =
   when_debug:
      if unlikely(opt.is_none()):
         OptError.throw($Opt[T] & " unpacking value failed")
   result = opt.val

proc unsafe_maybe_uninit_val*[T](opt: Opt[T]): lent T =
   if opt.is_val():
      result = opt.val
   else:
      result = default(T)

proc unsafe_maybe_uninit_take_val*[T](opt: sink Opt[T]): T =
   if opt.is_val():
      result = opt.val
   else:
      result = default(T)

template `?=`*(maybe_val: untyped, name: untyped): untyped =
   let temp_maybe_val = maybe_val
   let has_val = temp_maybe_val.is_val()
   var name = unsafe_maybe_uninit_take_val(temp_maybe_val)
   has_val

proc unwrap*[T](opt: sink Opt[T], msg: varargs[string, `$`]): T =
   let opt_temp = opt
   if unlikely(opt_temp.is_none()):
      {.line.}: failure(@msg)
   opt_temp.val

proc `$`*[T](opt: Opt[T]): string =
   if opt ?= val:
      result = "value(" & $val & ")"
   else:
      result = "none(" & $T & ")"

proc init*[E]: Res[Unit, E] {.attach.} =
   result.err = default(E)
   result.has_val = true

proc init*[T, E](val: sink T): Res[T, E] {.attach.} =
   result.val = val
   result.err = default(E)
   when T is Nilable:
      when_debug:
         if unlikely(result.val == nil):
            ResError.throw($Res[T, E] & " initialized with nil value")
   else:
      result.has_val = true

proc err*[T, E](err: E): Res[T, E] {.attach.} =
   result.err = err

proc is_ok*[T, E](res: Res[T, E]): bool =
   when T is Nilable:
      result = res.val != nil
   else:
      result = res.has_val

proc is_err*[T, E](res: Res[T, E]): bool =
   result = not res.is_ok()

proc unsafe_val*[T, E](res: Res[T, E]): lent T =
   when_debug:
      if unlikely(res.is_err()):
         ResError.throw($Res[T, E] & " unpacking value failed")
   result = res.val

proc unsafe_err*[T, E](res: Res[T, E]): lent E =
   when_debug:
      if unlikely(res.is_ok()):
         ResError.throw($Res[T, E] & " unpacking error failed")
   result = res.err

proc unsafe_take_val*[T, E](res: sink Res[T, E]): T =
   when_debug:
      if unlikely(res.is_err()):
         ResError.throw($Res[T, E] & " unpacking value failed")
   result = res.val

proc unsafe_take_err*[T, E](res: sink Res[T, E]): E =
   when_debug:
      if unlikely(res.is_ok()):
         ResError.throw($Res[T, E] & " unpacking error failed")
   result = res.err

proc unwrap*[E](
      res: sink Res[Unit, E],
      msg: varargs[string, `$`]): Unit {.discardable.} =
   let res_temp = res
   if unlikely(res_temp.is_err()):
      var msg_a = @msg
      if msg_a.len > 0:
         msg_a.add("failed to unwrap: " & $Res[Unit, E])
      {.line.}: failure(msg_a)
   res_temp.val

proc `$`*[T, E](res: Res[T, E]): string =
   if res.is_ok():
      result = "ok(" & $res.unsafe_val() & ")"
   else:
      result = "error(" & $res.unsafe_err() & ")"

macro unpack*(res: Res, branches: varargs[untyped]): untyped =
   let tmp_sym = nsk_var.init("res_tmp")
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
   result = stmt_concat(gen_var_val(tmp_sym, res),
                        nnk_if_stmt.init(if_branches))

proc or_val*[T](opt: Opt[T], fallback_val: T): T =
   result = if opt ?= val: val else: fallback_val
