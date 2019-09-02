import
  ./std_ext,
  ./std_ext/types

main_proc:
   block_of assert:
      int.tupled(3) is (int, int, int)
      no_ptr(ptr int) is int
      no_ref(ref seq[float]) is seq[float]
      seq[int] isnot Nilable
      ptr char is Nilable
      pointer is Nilable
      ref float32 is Nilable
