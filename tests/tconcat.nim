import
   std_ext

assert([1, 2] & [3, 4] == [1, 2, 3, 4])
assert(1 & [2, 3, 4] == [1, 2, 3, 4])
assert([1, 2, 3] & 4 == [1, 2, 3, 4])
