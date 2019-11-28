import std_ext
var x: seq[tuple[x: int, y: float]]
x.add_tup(3, 2.0)
assert(x[0].x == 3)
assert(x[0].y == 2.0)
