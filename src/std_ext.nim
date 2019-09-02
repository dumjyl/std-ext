import
   std_ext/private/std_ext/[types, attachs, initializers, meta, mem, dollars,
                            errors, type_traits, modes, c_strs]

export
   types,
   attachs,
   initializers,
   meta,
   mem,
   dollars,
   errors,
   type_traits,
   modes,
   c_strs

from sugar import dump
export dump

iterator items*(T: typedesc[bool]): bool {.inline.} =
   yield false
   yield true

template span*(n: isize): untyped =
   0 ..< n

template span*(x: untyped): untyped =
   low(x) .. high(x)

template rev*[T](`range`: Slice[T]): T =
   countdown(`range`.b, `range`.a)

template loop*(label: untyped, stmts: untyped): untyped =
   block label:
      while true:
         stmts

template loop*(stmts: untyped): untyped =
   while true:
      stmts

proc low*[T: u32|u64|usize](x: typedesc[T]): T =
   when size_of(T) == 8:
      result = cast[T](0'i64)
   elif size_of(T) == 4:
      result = cast[T](0'i32)
   else:
      {.error: "unsupported bitsize for low(u32|u64|usize)".}

proc high*[T: u32|u64|usize](x: typedesc[T]): T =
   when size_of(T) == 8:
      result = cast[T](-1'i64)
   elif size_of(T) == 4:
      result = cast[T](-1'i32)
   else:
      {.error: "unsupported bitsize for high(u32|u64|usize)".}

proc bit_cast*[From, To](x: From, T: typedesc[To]): T {.inline.} =
   result = cast[T](x)

proc bit_size_of*(T: typedesc): isize {.inline.} =
   result = size_of(T) * 8

proc `&`*[I0: static isize, I1: static isize, T](
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
