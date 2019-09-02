import
   ./types,
   ./attachs

proc alloc*(strs: openarray[string]): c_string_array {.attach, inline.} =
   result = alloc_c_string_array(strs)

proc free*(c_strs: c_string_array) =
   dealloc_c_string_array(c_strs)

proc to*(c_strs: c_string_array, T: typedesc[seq[string]]): seq[string] =
   result = c_string_array_to_seq(c_strs)

proc to*(c_strs: c_string_array, T: typedesc[seq[string]], len: isize): T =
   result = c_string_array_to_seq(c_strs, len)

proc len*(c_strs: c_string_array): isize =
   if c_strs == nil:
      result = 0
   else:
      var i = 0
      while c_strs[i] != nil:
         inc(i)
      result = i

iterator items*(c_strs: c_string_array): c_string {.inline.} =
   for i in 0 ..< c_strs.len:
      yield c_strs[i]

iterator pairs*(c_strs: c_string_array): tuple[idx: isize,
                                               val: c_string] {.inline.} =
   for i in 0 ..< c_strs.len:
      yield (i, c_strs[i])

type
   CStringArray* = object
      impl: c_string_array

proc inner*(c_strs: CStringArray): c_string_array =
   result = c_strs.impl

proc init*(strs: openarray[string]): CStringArray {.attach.} =
   result = CStringArray(impl: c_string_array.alloc(strs))

proc `=`*(dst: var CStringArray, src: CStringArray) =
   `=destroy`(dst)
   if src.impl.len > 0:
      dst.impl = cast[c_string_array](alloc0(size_of(c_string) *
                                             (src.impl.len+1)))
      for i, c_str in src.inner:
         dst.impl[i] = cast[c_string](alloc0(size_of(c_str[0]) * (c_str.len+1)))
         copy_mem(dst.impl[i], unsafe_addr c_str[0], c_str.len)

proc `=destroy`*(c_strs: var CStringArray) =
   if c_strs.impl != nil:
      c_strs.impl.free()

proc `=sink`*(dst: var CStringArray, src: CStringArray) =
   `=destroy`(dst)
   dst.impl = src.impl
