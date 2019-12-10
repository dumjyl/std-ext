import
   ../std_ext

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

template `?=`*(maybe_val: untyped, name: untyped): bool =
   let temp_maybe_val = maybe_val
   let has_val = temp_maybe_val.is_val()
   var name = unsafe_maybe_uninit_take_val(temp_maybe_val)
   has_val

template is_val(maybe_val: untyped, name: untyped): bool =
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

proc or_val*[T](opt: Opt[T], fallback_val: T): T =
   result = if opt ?= val: val else: fallback_val
