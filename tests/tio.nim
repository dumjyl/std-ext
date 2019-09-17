import
   std_ext,
   std_ext/io

proc t0 =
   var f = FileEx.init("tests/io_test0", fm_read)
   assert(f.len == 10)
   assert(f.pos == 0)
   f.pos = 5
   assert(f.pos == 5)
   assert(f.read(array[5, char]) == ['5', '6', '7', '8', '9'])
   assert(f.pos == 10)
   do_assert_raises(IOError):
      discard f.read(array[5, char])
   assert("tests/io_test0".read_file(string) == "0123456789")

proc t1 =
   var f = FileEx.init("tests/io_test1", fm_write)
   f.write(1)
   f.write(2)
   f.write(3)

proc t2 =
   assert("tests/io_test1".read_file(seq[isize]) == @[1, 2, 3])

t0()
t1()
t2()
