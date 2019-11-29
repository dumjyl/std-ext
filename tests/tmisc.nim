import
   std_ext,
   std_ext/dev_utils

var x: seq[tuple[x: int, y: float]]
x.add_tup(3, 2.0)
assert(x[0].x == 3)
assert(x[0].y == 2.0)

var xs = @[1, 2, 3]
for x in mutable(xs):
   x = x * 2
assert_eq(xs, @[2, 4, 6])
