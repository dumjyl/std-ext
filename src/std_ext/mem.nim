import
   ../std_ext,
   ./str_utils,
   std/bitops

export
   bitops

proc offset_u8*(x: pointer, i: isize): pointer {.inline.} =
   ## offset a ptr by ``i`` bytes
   result = (x.bit_cast(isize) + i).bit_cast(pointer)

proc offset*(x: pointer, i: isize): pointer {.inline.} =
   ## offset a ptr by ``i`` bytes
   result = x.offset_u8(i)

proc offset_u8*[T](x: ptr T, i: isize): ptr T {.inline.} =
   ## offset a ptr by ``i`` bytes
   result = (x.bit_cast(isize) + i).bit_cast(ptr T)

proc offset*[T](x: ptr T, i: isize): ptr T {.inline.} =
   ## offset a ptr by ``size_of(T)`` bytes
   result = x.offset_u8(i * size_of(T))

proc offset_u8*[T](
      x: ptr UncheckedArray[T],
      i: isize
      ): ptr UncheckedArray[T] {.inline.} =
   ## offset a ptr by ``i`` bytes
   result = (x.bit_cast(isize) + i).bit_cast(ptr UncheckedArray[T])

proc offset*[T](
      x: ptr UncheckedArray[T],
      i: isize
      ): ptr UncheckedArray[T] {.inline.} =
   ## offset a ptr by ``size_of(T)`` bytes
   result = x.offset_u8(i * size_of(T))

proc repr_bin*(x: pointer|SomeNumber): string =
   result = string.init(bit_size_of(x))
   when x is pointer:
      var x = x.bit_cast(usize)
   for i in rev(span(result)):
      result[^(i+1)] = if bit_and(x shr i, 1) == 0: '0' else: '1'

proc repr_hex*(x: pointer|SomeNumber): string =
   when x is pointer:
      var x = x.bit_cast(usize)
   result = to_hex(x)
