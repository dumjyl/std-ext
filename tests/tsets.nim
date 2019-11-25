import
   std_ext/sets

let nums = [1, 3, 6, 7]
var x = Set.init(nums)
var y = Set[int].init(nums)
assert(x.len == 4)
assert(y.len == 4)
for i in nums:
   assert(x.contains(i))
   assert(y.contains(i))
