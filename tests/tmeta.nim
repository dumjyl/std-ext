import
   ./std_ext

template reject(stmts: untyped) =
   assert(not compiles(stmts))

main_proc:
   block:
      var sum = 0
      visits(cur := 0):
         sum += cur
         if cur < 3:
            visit(cur + 1)
      assert(sum == 6)

   block:
      var sum = 0
      unroll(i, [1, 3, 9]):
         var x = i
         sum += x
      assert(sum == 13)

   block:
      reject:
         var sum = 0
         unroll_dirty(i, [1, 3, 9]):
            var x = i
            sum += x
         assert(sum == 13)

   block:
      var i = 0
      unroll typ, [i32, seq[f64], pointer]:
         case i:
         of 0: assert(typ is i32)
         of 1: assert(typ is seq[f64])
         of 2: assert(typ is pointer)
         else: assert(false)
         inc(i)
