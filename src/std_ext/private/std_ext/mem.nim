import
   ./types

proc mem*[T](x: var seq[T], offset: isize = 0): ptr T {.inline.} =
   result = addr x[offset]

proc unsafe_mem*[T](x: seq[T], offset: isize = 0): ptr T {.inline.} =
   result = unsafe_addr x[offset]

proc mem*[I, T](x: var array[I, T], offset = low(I)): ptr T {.inline.} =
   result = addr x[offset]

proc unsafe_mem*[I, T](x: array[I, T], offset = low(I)): ptr T {.inline.} =
   result = unsafe_addr x[offset]

proc mem*(x: var string, offset: isize = 0): ptr char {.inline.} =
   result = addr x[offset]

proc unsafe_mem*(x: var string, offset: isize = 0): ptr char {.inline.} =
   result = unsafe_addr x[offset]

proc mem*[T](x: var openarray[T], offset: isize = 0): ptr T {.inline.} =
   result = addr x[0]

proc unsafe_mem*[T](x: openarray[T], offset: isize = 0): ptr T {.inline.} =
   result = unsafe_addr x[0]
