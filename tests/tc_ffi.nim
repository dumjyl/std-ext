
#[
backends: c, c++
output:
4
4
4
4
/
]#

import
   ./std_ext,
   ./std_ext/c_ffi,
   ./std_ext/c_ffi/mem

anon:
   block:
      var x: i32
      echo c_size_of(x)
      echo c_size_of(i32)
      echo size_of(x)
      echo size_of(i32)
