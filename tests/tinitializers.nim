import
   std_ext,
   std_ext/dev_utils

type
   Obj[T] = object
      str: string
      i32: int32
      val: T
   RefObj[T] = ref object
      val: T
   PtrObj[T] = ptr object
      val: T

proc init*[T](
      Self: type[Obj[T]],
      str: string,
      i32: int32,
      val: T
      ): Obj[T] =
   result = Obj[T](str: str, i32: i32, val: val)


proc init*[T](Self: type[RefObj[T]], val: T): RefObj[T] =
   result = RefObj[T](val: val)

proc init*[T](Self: type[PtrObj[T]], val: T): PtrObj[T] =
   type Temp = deref(PtrObj[T])
   result = create(Temp)
   result[] = Temp(val: val)

proc init*(Self: type[ref int8], val: int8): Self =
   new(result)
   result[] = val * 2

proc init*(Self: type[ptr int8], val: int8): Self =
   result = create(int8)
   result[] = val * 2

run:
   block_of assert:
      Obj.init("abc", 123'i32, @[1, 2, 3]) == Obj[seq[int]](str: "abc",
                                                            i32: 123.i32,
                                                            val: @[1, 2, 3])
      string.init(5).len == 5
      seq[int].init(5).len == 5
      string.of_cap(5).len == 0
      seq[int].of_cap(5).len == 0
   block ref_tests:
      let x0 = (ref int).init(38) # call generic ref init from std_ext
      assert_eq(x0[], 38)
      assert(type_of(x0) is ref int)

      let x1 = (ref int8).init(12'i8) # call ref int8 init from here
      assert_eq(x1[], 24)
      assert(type_of(x1) is ref int8)

      let x2 = RefObj.init("ref_obj") # call RefObj init from here.
      assert_eq(x2.val, "ref_obj")
      assert(type_of(x2) is RefObj[string])

      # XXX: generic arg required here.
      let x3 = (ref RefObj[string]).init(x2)
      assert_eq(x3.val, "ref_obj")
      assert(type_of(x3) is ref RefObj[string])

      let x4 = (ref Obj).init("ref Obj", 432, "str2")
      let x5 = (ref Obj[string]).init("ref Obj", 432, "str2")
      assert_eq(x4.str, "ref Obj")
      assert_eq(x4.i32, 432)
      assert_eq(x4.val, "str2")
      
      # XXX: better handling of anon objects or object without init calls.
      #let x6 = RefObj[string].init(x2[])

   block ptr_tests:
      let x0 = (ptr int).init(38) # call generic ref init from std_ext
      assert_eq(x0[], 38)
      assert(type_of(x0) is ptr int)

      let x1 = (ptr int8).init(12'i8) # call ref int8 init from here
      assert_eq(x1[], 24)
      assert(type_of(x1) is ptr int8)

      let x2 = PtrObj.init("ptr_obj") # call RefObj init from here.
      assert_eq(x2.val, "ptr_obj")
      assert(type_of(x2) is PtrObj[string])

      # XXX: generic arg required here.
      let x3 = (ptr PtrObj[string]).init(x2)
      assert_eq(x3.val, "ptr_obj")
      assert(type_of(x3) is ptr PtrObj[string])

      let x4 = (ptr Obj).init("ptr Obj", 432, "str2")
      let x5 = (ptr Obj[string]).init("ptr Obj", 432, "str2")
      assert_eq(x4.str, "ptr Obj")
      assert_eq(x4.i32, 432)
      assert_eq(x4.val, "str2")
