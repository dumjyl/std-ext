include system/[fatal, indexerrors]

import
   ../std_ext

# type
#    Vec*[T] = object
#       len, cap: isize
#       data: ptr UncheckedArray[T]
#    SmallVec*[N: static isize; T] = object
#       len, cap: isize
#       data: ptr UncheckedArray[T]
#       small_data: array[N, T]

proc check_bounds(i: isize, len: isize) =
   when compile_option("bound_checks"):
      if i < 0 or i >= len:
         sys_fatal(IndexError, format_error_index_bound(i, len-1))

type
   FixedVec*[N: static isize; T] = object
      len: isize
      data: array[N, T]

proc `=destroy`*[N: static isize; T](x: var FixedVec[N, T]) =
   for i in 0 ..< x.len:
      `=destroy`(x.data[i])

proc `=`*[N: static isize; T](dst: var FixedVec[N, T]; src: FixedVec[N, T]) =
   `=destroy`(dst)
   dst.len = src.len
   for i in 0 ..< dst.len:
      dst.data[i] = src.data[i]

proc `=sink`*[N: static isize; T](dst: var FixedVec[N, T],
                                  src: FixedVec[N, T]) =
   `=destroy`(dst)
   dst.len = src.len
   dst.data = src.data

proc init*[N: static isize; T]: FixedVec[N, T] {.attach.} =
   result.len = 0
   result.data = default(array[N, T])

proc init*[N: static isize; T](len: isize): FixedVec[N, T] {.attach.} =
   result.len = len
   result.data = default(array[N, T])

proc len*[N: static isize; T](x: FixedVec[N, T]): isize =
   result = x.len

proc low*[N: static isize; T](x: FixedVec[N, T]): isize =
   result = 0

proc high*[N: static isize; T](x: FixedVec[N, T]): isize =
   result = x.len - 1

proc `[]`*[N: static isize; T](x: FixedVec[N, T]; i: isize): T =
   check_bounds(i, x.len)
   result = x.data[i]

proc `[]`*[N: static isize; T](x: var FixedVec[N, T]; i: isize): var T =
   check_bounds(i, x.len)
   result = x.data[i]

proc `[]=`*[N: static isize; T](x: var FixedVec[N, T]; i: isize, val: T) =
   check_bounds(i, x.len)
   x.data[i] = val

proc add*[N: static isize; T](x: var FixedVec[N, T], val: T) =
   when compile_option("bound_checks"):
      if x.len == N:
         sys_fatal(IndexError, "cannot grow container beyond: " & $N)
   x.data[x.len] = val
   inc(x.len)

proc set_len*[N: static isize; T](x: var FixedVec[N, T], len: isize) =
   for i in len ..< x.len:
      `=destroy`(x.data[i])
   x.len = len

iterator items*[N: static isize; T](x: FixedVec[N, T]): T =
   for i in span(x):
      yield x.data[i]

proc `$`*[N: static isize; T](x: FixedVec[N, T]): string =
   result = "["
   var first = true
   for val in x:
      if not first:
         result &= ", "
      result &= $val
      first = false
   result &= "]"
