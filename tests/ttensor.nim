import
   pkg/std_ext,
   pkg/std_ext/[tensor, option, macros]

# proc test_f32s[I](shape: array[I, isize]): auto =
#    result = Tensor[shape.len, f32].init(shape)
#    unroll

proc test_data[I](T: typedesc, shape: array[I, isize]): auto =
   result = Tensor[shape.len, T].init(shape)
   var i = 0
   template impls(Dim: static isize, idxs: typed = []): untyped =
      when Dim == 0:
         make_call(`[]=`, result, splat(idxs), T(i))
         inc(i)
      else:
         for idx in result.shape(result.N - Dim):
            impls(Dim - 1, concat_args(idxs, idx, nnk_bracket))
   impls(shape.len)

main_proc:
   # block:
   #    let x = test_data(i32, [3, 6, 9, 12])
   #    assert(x[0].shape == [6, 9, 12])
   #    assert(x[1, skip, 2].shape == [6, 12])
   #    echo x
   block:
      let x = test_data(i32, [5, 4, 5, 4])
      echo x
   block:
      let x = test_data(f32, [8, 3, 32, 64])
      assert x.shape == [8, 3, 32, 64]
      assert x.stride == [some(6144), some(2048), some(64), some(1)]
      assert x.offset == [some(0), some(0), some(0), some(0)]
      assert(x[1, 1, 1, 3] == 3 * 32 * 64 + 32 * 64 + 64 + 3)
   block:
      discard
