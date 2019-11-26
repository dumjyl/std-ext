import
   ./std_ext,
   ./std_ext/c_ffi,
   ./std_ext/c_ffi/mem

run:
   block:
      var x: i32
      assert(c_size_of(x) == 4)
      assert(c_size_of(i32) == 4)
   #block:
      #let x = cpp_unique_ptr.init(init_ptr(100))
      #let y = cpp_unique_ptr[int].init(init_ptr(100))
