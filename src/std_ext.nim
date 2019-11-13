import
   std_ext/private/std_ext/[iterators,
                            types,
                            attachs,
                            initializers,
                            meta,
                            mem,
                            dollars,
                            errors,
                            modes,
                            c_strs,
                            seq_ext]

export
   iterators,
   types,
   attachs,
   initializers,
   meta,
   mem,
   dollars,
   errors,
   modes,
   c_strs,
   seq_ext

from sugar import
   dump,
   `=>`,
   `->`
export
   dump,
   `=>`,
   `->`

template loop*(label: untyped, stmts: untyped): untyped =
   block label:
      while true:
         stmts

template loop*(stmts: untyped): untyped =
   while true:
      stmts

proc low*[T: u32|u64|usize](PT: typedesc[T]): T =
   when size_of(T) == 8:
      result = cast[T](0'i64)
   elif size_of(T) == 4:
      result = cast[T](0'i32)
   else:
      {.error: "unsupported bitsize for low(u32|u64|usize)".}

proc high*[T: u32|u64|usize](PT: typedesc[T]): T =
   when size_of(T) == 8:
      result = cast[T](-1'i64)
   elif size_of(T) == 4:
      result = cast[T](-1'i32)
   else:
      {.error: "unsupported bitsize for high(u32|u64|usize)".}

proc bit_cast*[From, To](x: From, PTo: typedesc[To]): To {.inline.} =
   result = cast[To](x)

proc bit_size_of*[T](PT: typedesc[T]): isize {.inline.} =
   result = size_of(T) * 8

proc bit_size_of*[T](x: T): isize {.inline.} =
   result = size_of(x) * 8

proc `&`*[
      I0: static isize,
      I1: static isize,
      T](
      a: array[I0, T],
      b: array[I1, T]
      ): array[I0 + I1, T] =
   for i in span(I0):
      result[i] = a[i]
   for i in span(I1):
      result[I0 + i] = b[i]

proc `&`*[I: static isize, T](a: array[I, T], b: T): array[I + 1, T] =
   for i in span(I):
      result[i] = a[i]
   result[I] = b

proc `&`*[I: static isize, T](a: T, b: array[I, T]): array[I + 1, T] =
   result[0] = a
   for i in span(I):
      result[1+i] = b[i]

template static_assert*(cond: untyped, msg = "") =
   static: do_assert(cond, msg)

template deref*[T](x: ptr T): var T =
   x[]

template deref*[T](x: ref T): var T =
   x[]

template type_of_or_void*(expr: untyped): typedesc =
   ## Return the type of ``expr`` or ``void`` on error.
   when compiles(type_of(expr)):
      type_of(expr)
   else:
      void

from os import parent_dir

template cur_src_dir*: untyped =
  parent_dir(instantiation_info(-1, true).filename)

template cur_src_file*: untyped =
  instantiation_info(-1, true).filename
