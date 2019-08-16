type
  Nilable* = ref | ptr | pointer | c_string | c_string_array

template no_ptr*[T](PtrT: typedesc[ptr T]): typedesc =
  T

template no_ref*[T](RefT: typedesc[ref T]): typedesc =
  T
