import
   pkg/std_ext,
   pkg/std_ext/vec_ops

var x = [1, 2, 3, 4]
var x_seq = @[1, 2, 3, 4]
block_of assert:
   x + x == [2, 4, 6, 8]
   x + 1 == [2, 3, 4, 5]
   1 + x == [2, 3, 4, 5]
   x_seq + x_seq == @[2, 4, 6, 8]
   x_seq + 1 == @[2, 3, 4, 5]
   1 + x_seq == @[2, 3, 4, 5]
   x / 2 == [0.5, 1.0, 1.5, 2.0]
   [4'f32, 8, 20, 1, 2, 6].std_dev == 6.940220832824707
