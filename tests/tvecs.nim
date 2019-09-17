import
   std_ext,
   std_ext/vecs

main_proc:
   var x: FixedVec[2, i8]
   assert(x.len == 0)
   assert($x == "[]")
   do_assert_raises(IndexError): echo x[4]
   do_assert_raises(IndexError): x[4] = 45'i8
   x.add(38'i8)
   assert($x == "[38]")
   x.add(2'i8)
   x[1].inc
   assert($x == "[38, 3]")
   do_assert_raises(IndexError): x.add(6'i8)

