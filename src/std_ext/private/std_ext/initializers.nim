import
   ../../macros,
   ./attachs,
   ./iterators,
   ./types

macro auto_init*(fn: untyped): untyped =
   var init_stmt = gen_call("impl_auto_init", copy(fn[3][0]))
   for i in 1 ..< fn[3].len:
      init_stmt.add(fn[3][i].def_syms)
   result = fn
   if fn.body.kind == nnk_empty:
      result.body = init_stmt
   else:
      result.body.insert(0, init_stmt)

macro impl_auto_init*(T: typedesc, params: varargs[typed]): untyped =
   result = gen_stmts("init".gen_call(id"result"))
   for field in T.record_impl.field_syms:
      for param in params:
         if `id==`(field, param):
            result.add(quote do:
               when result.`field` is type_of(`param`):
                  result.`field` = `param`)

macro impl_init_from*(
      TInto, TFrom: typedesc,
      into_val, from_val: typed
      ): untyped =
   result = gen_stmts()
   for field_into in TInto.record_impl.field_syms:
      for field_from in TFrom.record_impl.field_syms:
         if `id==`(field_into, field_from):
            result.add(quote do:
               when `into_val`.`field_into` is type_of(`from_val`.`field_from`):
                  `into_val`.`field_into` = `from_val`.`field_from`)

proc init_from*[
      TInto: object|ref object|tuple,
      TFrom: object|ref object|tuple](
      PTInit: typedesc[TInto],
      from_val: TFrom,
      ): TInto =
   mixin init
   result = init(TInto)
   impl_init_from(TInto, TFrom, result, from_val)

proc init_from*[
      TInto: object|ref object|tuple,
      TFrom: object|ref object|tuple](
      into_val: var TInto,
      from_val: TFrom) =
   mixin init
   into_val = init(TInto)
   impl_init_from(TInto, TFrom, into_val, from_val)

proc init*[
      T: bool|char|string|c_string|pointer|SomeNumber|seq|set
      ]: T {.attach, inline.} =
   result = default(T)

proc init*[T: object]: T {.attach, inline.} =
   mixin init
   for f in fields(result):
      init(f)

proc init*[T: tuple]: T {.attach, inline.} =
   mixin init
   for f in fields(result):
      init(f)

proc init*[T: ref object]: T {.attach, inline.} =
   mixin init
   new result
   for f in fields(result):
      init(f)

proc init*[T: enum]: T {.attach, inline.} =
   result = low(T)

proc init*[T: range]: T {.attach, inline.} =
   result = low(T)

proc init*[I; T]: array[I, T] {.attach, inline.} =
   mixin init
   for i in span(I):
      result[i] = init(T)

proc init*[T](x: var T) {.inline.} =
   mixin init
   x = init(T)

proc init*(len: Natural = 0.Natural): string {.attach, inline.} =
   result = new_string(len)

proc of_cap*(cap: Natural): string {.attach, inline.} =
   result = new_string_of_cap(cap)

proc init*[T](len: Natural = 0.Natural): seq[T] {.attach, inline.} =
   result = new_seq[T](len)
   for i in span(result):
      result[i] = init(T)

proc of_cap*[T](cap: Natural): seq[T] {.attach, inline.} =
   result = new_seq_of_cap[T](cap)
