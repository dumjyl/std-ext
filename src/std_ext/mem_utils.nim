import
   ../std_ext,
   ./str_utils,
   ./checks,
   core/allocators as std_allocators

export
   std_allocators

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

proc alloc*(
      allocator: Allocator,
      bytes: isize,
      alignment: isize = 8,
      ): pointer {.inline.} =
   result = allocator[].alloc(allocator, bytes, alignment)

proc dealloc*(
      allocator: Allocator,
      allocation: pointer,
      bytes: isize = 0) {.inline.} =
   allocator[].dealloc(allocator, allocation, bytes)

proc realloc*(
      allocator: Allocator,
      allocation: pointer,
      bytes_old: isize,
      bytes_new: isize,
      ): pointer {.inline.} =
   result = allocator[].realloc(allocator, allocation, bytes_old, bytes_new)

proc realloc*(
      allocator: Allocator,
      allocation: pointer,
      bytes: isize,
      ): pointer {.inline.} =
   result = realloc(allocator, allocation, 0, bytes)

type
   DecResultKind* = enum
      DecAlive
      DecFreed
   RcData*[T] = ptr object
      ref_count: isize
      len: isize
      allocator: Allocator
      data: UncheckedArray[T]

proc len*[T](self: RcData[T]): isize =
   result = self.len

proc low*[T](self: RcData[T]): isize =
   result = 0

proc high*[T](self: RcData[T]): isize =
   result = self.len - 1

template span*[T](self: RcData[T]): untyped =
   low(self) .. high(self)

proc `[]`*[T](self: RcData[T], i: isize): var T =
   check_bounds(i, self.len)
   result = self.data[i]

proc `[]=`*[T](self: RcData[T], i: isize, val: T) =
   check_bounds(i, self.len)
   self.data[i] = val

proc `$`*[T](self: RcData[T]): string =
   result = "["
   for i in span(self):
      if i != 0:
         result &= ", "
      result &= $self[i]
   result &= "]"

proc init*[T](
      len: isize,
      allocator = get_local_allocator(),
      zero_mem = true,
      ): RcData[T] {.attach.} =
   let bytes = size_of(result[]) + size_of(T) * len
   result = alloc(allocator, bytes).bit_cast(RcData[T])
   if result == nil:
      OutOfMemError.throw("failed to allocate memory for " & $len & " " & $T)
   else:
      result.ref_count = 1
      result.len = len
      result.allocator = allocator
   if zero_mem and ZerosMem notin allocator.flags:
      zero_mem(addr result.data[0], size_of(T) * len)

proc deinit*[T](self: RcData[T]) =
   dealloc(self.allocator, self, size_of(T) * self.len)

proc inc_ref*[T](self: RcData[T]) =
   inc(self.ref_count)

proc dec_ref*[T](self: RcData[T]): DecResultKind {.discardable.} =
   dec(self.ref_count)
   if self.ref_count <= 0:
      result = DecFreed
      deinit(self)
   else:
      result = DecAlive

template unsafe_set*[T0, T1](lhs: var T0, rhs: T1) =
   lhs.addr.bit_cast(ptr T1).deref() = rhs
