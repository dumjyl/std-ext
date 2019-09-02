import
   std_ext,
   std_ext/array_nd,
   std_ext/seq_utils

template reject(stmts: untyped) =
   assert(not compiles(stmts))

main_proc:
   block N1:
      var x = Array[f32, 1].init([16])
      reject(x[1, 2])
      for i in x.shape(0):
         assert(x[i] == 0)
      for i in x.shape(0):
         x[i] = 3
      for i in x.shape(0):
         assert(x[i] == 3)
   block N2:
      var x = Array[isize, 2].init([2, 8])
      var i = 0
      for i0 in x.shape(0):
         for i1 in x.shape(1):
            x[i0, i1] = i
            inc(i)
      assert(x.data_copy == to_seq(0 ..< 16))
      reject(x[0, [1, 2, 3]])
   #   assert(x[7] == 2)
   # block N2:
   #   var x = Array[i8, 2].filled([4, 4], 32)
   #   assert(x[3, 3] == 32)
   # block N4:
   #    var x = Array[i32, 4].init([4, 2, 16, 38])
   #    assert(x.shape == [4, 2, 16, 38])
   #    assert(x[skip].shape == x.shape)
   #    assert(x[skip, skip, skip, skip].shape == x.shape)
   #    assert(x[skip, skip, 0, 0].shape == [4, 2])
   #    assert(x[0, skip, skip, 0].shape == [2, 16])
   #    assert(x[0, 0, skip, skip].shape == [16, 38])
   #    assert(x[[1, 2, 3]].shape == [3, 2, 16, 38])
   #    assert(x[0].shape == [2, 16, 38])
   #    assert(x[0, 0].shape == [16, 38])
   #    assert(x[0, 0, 0].shape == [38])
   #    var y0 = x[2, [1, 0], 0 ..< 12, @[1, 32, 36]]
   #    assert(y0.shape == [2, 12, 3])
   #    echo x[1, 2, 3, 4]
   # var x0 = Array[f32, 2].init([8, 8])
   # var x1 = Array[f32, 3].filled([3, 32, 32], 38'f32)
   # for ci in span(3):
      # for yi in span(3):
         # for xi in span(3):
         # assert(x1[ci, yi, xi] == 38)
      # var x2 = Array[f64].zeros([4, 4])
      # var x3 = Array[i64].ones([4, 4, 4, 4])
      # var x3 = SeqND.filled([8, 2], ['a', 'b', 'c', 'd'])
      # assert(x3[7, 1] == ['a', 'b', 'c', 'd'])
      # x1[3, 3] = 52
      # assert(x1[3, 3] == 52)
