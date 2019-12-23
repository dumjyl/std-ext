import
   ./std_ext,
   ./std_ext/options

run:
   assert(size_of(Opt[i8]) == 2)
   assert(size_of(Opt[ref i8]) == 8)
   type
      MaybeFloat = Opt[ref f32]
   var x: ref f32
   sec(debug):
      do_assert_raises OptError: discard some(x)
   var y = new(f32)

   var a_nil = string.none()
   assert($a_nil == "none(string)")
   assert(a_nil.is_none())
   var b_nil = (ref f32).none()
   assert(b_nil.is_none())
   var a_has = some("str")
   assert($a_has == "value(str)")
   assert(a_has.is_val())
   var b_has = some(y)
   assert(b_has.is_val())

   if a_has as some(str):
      assert(str == "str")
   assert(a_nil as none)

   var nil_path = false
   assert((if a_nil as some(str): "str" else: "nil str") == "nil str")
