import
   ./std_ext,
   ./std_ext/c_ffi

main_proc:
   var x: i32
   assert(c_size_of(x) == 4)
   assert(c_size_of(i32) == 4)
