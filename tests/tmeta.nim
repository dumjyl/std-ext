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
