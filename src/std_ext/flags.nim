import
   ../std_ext,
   ./macros,
   ./bit_utils
from std/math import ceil, next_power_of_two

template INTERNAL_data_type*(T: typedesc): untyped =
   array[isize(ceil(len(T) / 8)), u8]

type
   Flags*[T: enum] = object
      data: INTERNAL_data_type(T)

macro impl_val_or_pos(
      T: typedesc[enum],
      val: typed,
      is_value: static bool
      ): auto =
   result = nnk_case_stmt.init(val)
   let typ = T.typ
   typ.needs_kind(nnk_enum_ty)
   for i in 1 ..< typ.len:
      let val = typ[i].int_val.isize
      if i - 1 != val:
         result.add(
            if is_value: nnk_of_branch.init(gen_lit(i - 1), typ[i])
            else: nnk_of_branch.init(typ[i], gen_lit(i - 1)))
   let else_call = gen_call(if is_value: T else: id"ord", val)
   if result.len == 1:
      result = else_call
   elif result.len != typ.len or is_value:
      result.add(nnk_else.init(else_call))

proc `[]`*[T: enum](self: Flags[T], i: isize): bool =
   result = bit_and(self.data[i div 8], 1'u8 shl (i mod 8)) != 0

proc `[]=`*[T: enum](self: var Flags[T], i: isize, val: static[bool]) =
   when val:
      self.data[i div 8] = bit_or(self.data[i div 8], 1'u8 shl (i mod 8))
   else:
      self.data[i div 8] = bit_and(self.data[i div 8],
                                   bit_not(1'u8 shl (i mod 8)))

proc position[T: enum](val: T): isize =
   result = impl_val_or_pos(T, val, is_value = false)

proc value[T: enum](pos: isize): T =
   result = impl_val_or_pos(T, pos, is_value = true)

proc contains*[T: enum](self: Flags[T], val: T): bool =
   result = self[position(val)]

proc incl*[T: enum](self: var Flags[T], val: T) =
   self[position(val)] = true

proc excl*[T: enum](self: var Flags[T], val: T) =
   self[position(val)] = false

proc init*[T: enum](xs: openarray[T]): Flags[T] {.attach.} =
   for x in xs:
      result.incl(x)

proc init*[T: enum](xs: varargs[T]): Flags[T] {.attach.} =
   for x in xs:
      result.incl(x)

iterator items*[T: enum](self: Flags[T]): T {.inline.} =
   for i in 0 ..< self.data.len * 8:
      if self[i]:
         yield value[T](i)

iterator pairs*[T: enum](self: Flags[T]): (isize, T) {.inline.} =
   var i = 0
   for flag in self:
      yield (i, flag)
      inc(i)

proc `$`*[T: enum](self: Flags[T]): string =
   result = "{"
   var first = true
   for flag in self:
      if first:
         first = false
      else:
         result &= ", "
      result &= $flag
   result &= "}"

test:
   template reject(stmts: untyped) =
      assert(not compiles(stmts))

   template accept(stmts: untyped) =
      assert(not compiles(stmts))

   type
      Simple = enum A, B, C, D
      HoledEnum = enum k0 = -3'i64, k1 = -2'i64, k2 = 1'i64, k3 = 3'i64, k4 = 234'i64

test_proc:
   block:
      var x = Flags.init(k0, k4)
      assert(k0 in x)
      assert(k4 in x)
      x.excl(k0)
      x.excl(k4)
      assert($x == "{}")
   block:
      var x = Flags.init(A, C)
      assert(A in x)
      assert(C in x)
      x.excl(A)
      x.excl(B)
      assert(A notin x)
      assert(B notin x)
      x.incl(B)
      assert(B in x)
      var ran = false
      for i, flag in x:
         case i:
         of 0: assert(flag == B)
         of 1:
            assert(flag == C)
            ran = true
         else: assert(false)
      assert(ran)
      assert(size_of(x) == 1)
      echo size_of(set[HoledEnum])
      echo size_of(set[Simple])
