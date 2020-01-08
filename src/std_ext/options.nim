import
   private/std_ext/[types,
                    fixup_varargs,
                    errors],
   macros

type
   OptError* = object of Defect
   Opt*[T] = object
      when T is Nilable:
         val: T
      else:
         val: T
         has_val: bool

proc some*[T](val: sink T): Opt[T] =
   result.val = val
   when T is Nilable:
      when not defined(release):
         if unlikely(result.val == nil):
            OptError.throw($Opt[T] & " initialized with nil value")
   else:
      result.has_val = true

proc none*(Self: type): Opt[Self] {.inline.} =
   result = default(Opt[Self])

proc is_val*[T](opt: Opt[T]): bool =
   when T is Nilable:
      result = opt.val != nil
   else:
      result = opt.has_val

proc is_some*[T](opt: Opt[T]): bool =
   result = opt.is_val()

proc is_none*[T](opt: Opt[T]): bool =
   result = not opt.is_val()

proc unsafe_val*[T](opt: Opt[T]): T =
   when not defined(release):
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

macro `as`*(option_val: untyped, as_kind: untyped): untyped =
   runnable_examples:
      let opt = some(24)
      if opt as some(val):
         echo "has value: ", val
      else:
         echo "no value"
   if `id==`(as_kind, "none"):
      result = quote do:
         is_none(`option_val`)
   elif as_kind.kind in nnk_call_kinds and as_kind.len == 2 and
         (`id==`(as_kind[0], "some") or `id==`(as_kind[0], "val")) and
         as_kind[1].kind == nnk_ident:
      let name = as_kind[1]
      result = quote do:
         let tmp = `option_val`
         let has_val = is_val(tmp)
         var `name` = unsafe_maybe_uninit_take_val(tmp)
         has_val
   else:
      error("unexpected `Opt` unpack expression: " & repr as_kind)

proc `$`*[T](opt: Opt[T]): string =
   if opt as some(val):
      result = "value(" & $val & ")"
   else:
      result = "none(" & $T & ")"

proc or_val*[T](opt: Opt[T], fallback_val: T): T =
   result = if opt as some(val): val else: fallback_val

proc unwrap*[T](opt: sink Opt[T], msg: varargs[string, `$`]): T =
   let opt_temp = opt
   if unlikely(opt_temp.is_none()):
      {.line.}: fixup_varargs fatal(msg)
   opt_temp.val
