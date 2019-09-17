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
      is_signed(i8)
      is_signed(isize)
      not is_signed(u8)
      not is_signed(usize)
      float.with_size(32) is f32
      u8.to_signed is i8
      u8.is_unsigned
      i32.is_signed
      i32.with_size(32)(54) == 54
      u32.with_size(isize) is usize
