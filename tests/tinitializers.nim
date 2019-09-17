import
   ./std_ext

type
   TInit[T] = object
      str: string
      i32: int32
      val: T
   TInitOther[T] = ref object
      str: string
      i32: int32
      val: T
   R = range[43'u8..200'u8]

proc init*[T](str: string, i32: int32, val: T): TInit[T] {.attach, auto_init.}

main_proc:
   block_of assert:
      TInit.init("abc", 123'i32, @[1, 2, 3]) == TInit[seq[int]](str: "abc",
                                                                i32: 123.i32,
                                                                val: @[1, 2, 3])
      string.init(5).len == 5
      seq[int].init(5).len == 5
      string.of_cap(5).len == 0
      seq[int].of_cap(5).len == 0
   block:
      let x = array[10, R].init()
      assert(x[^1] == 43)
   block:
      let x = TInitOther[int32].init_from(TInit.init("123", 4'i32, ['a', 'b']))
      let y = TInit[string].init_ref("ref", 64'i32, "inited")
      let z = TInit[string].init_ptr(y[])
      block_of assert:
         x.str == "123"
         x.i32 == 4'i32
         y.str == "ref"
         y.i32 == 64'i32
         y.val == "inited"
         z.str == "ref"
         z.i32 == 64'i32
         z.val == "inited"
      dealloc(z)
