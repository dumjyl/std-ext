import
   std_ext/sets

var x = Set.init([1, 3, 6, 7])
for i in [1, 3, 6, 7]:
   assert(x.contains(i))
