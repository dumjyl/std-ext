import
  ./std_ext,
  ./std_ext/option

run:
   assert(size_of(Opt[i8]) == 2)
   assert(size_of(Opt[ref i8]) == 8)
   type MaybeFloat = Opt[ref f32]
   var x: ref f32
   when_debug:
      do_assert_raises OptError: discard MaybeFloat.init(x)
      do_assert_raises OptError: discard Opt.init(x)
      do_assert_raises OptError: discard Opt[ref f32].init(x)
   var y = new(f32)

   var a_nil = string.none()
   assert($a_nil == "none(string)")
   assert(a_nil.is_none())
   var b_nil = (ref f32).none()
   assert(b_nil.is_none())
   var a_has = Opt.init("str")
   assert($a_has == "value(str)")
   assert(a_has.is_val())
   var b_has = Opt.init(y)
   assert(b_has.is_val())

   if a_has ?= str:
      assert(str == "str")

   var nil_path = false
   assert((if a_nil ?= str: "str" else: "nil str") == "nil str")

   type
      IntsRes = Res[int, int]
      UnitRes = Res[Unit, int]
   var
      a = IntsRes.init(3)
      b = Res[int, int].init(4)
      c = UnitRes.init()
      d = Res[Unit, int].init()
   block_of assert:
      a.is_ok()
      b.is_ok()
      c.is_ok()
      d.is_ok()
      $c == "ok(())"
   a = IntsRes.err(3)
   b = Res[int, int].err(4)
   c = UnitRes.err(5)
   d = Res[Unit, int].err(6)
   block_of assert:
      a.is_err()
      b.is_err()
      c.is_err()
      d.is_err()
      $c == "error(5)"

   type ErrorKinds = enum OutOfMem, Uninitialized, SomethingElse
   for res in [Res[int, ErrorKinds].init(3),
               Res[int, ErrorKinds].err(OutOfMem)]:
      unpack res:
      of val := T:
         assert(val == 3)
      of err := E:
         assert(err == OutOfMem)
