import
   ./types,
   ../../macros

iterator items*(T: typedesc[bool]): bool {.inline.} =
   for val in [false, true]:
      yield val

template span*(n: isize): untyped =
   0 ..< n

template span*(x: untyped): untyped =
   low(x) .. high(x)

template rev*[T](`range`: Slice[T]): T =
   countdown(`range`.b, `range`.a)

template fields*[T: ref object](x: T): untyped {.dirty.} =
   fields(x[])

template fields_pairs*[T: ref object](x: T): untyped {.dirty.} =
   fields_pairs(x[])

template mutable*[T](vals: var seq[T]): untyped =
   m_items(vals)
