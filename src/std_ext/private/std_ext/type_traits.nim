import
   ./types,
   ../../macros

type
   Nilable* = ref | ptr | pointer | c_string | c_string_array
   PtrSized* = isize | usize | ptr | pointer

template no_ptr*[T](PT: typedesc[ptr T]): typedesc =
   T

template no_ref*[T](PT: typedesc[ref T]): typedesc =
   T

template is_signed*[T: SomeNumber](PT: typedesc[T]): bool =
   when T is SomeSignedInt or T is SomeFloat: true
   elif T is SomeUnsignedInt: false
   else: {.error: "unhandled type: " & $T.}

template is_unsigned*[T: SomeNumber](PT: typedesc[T]): bool =
   not is_signed(PT)

template with_size*
      [T: SomeSignedInt](
      PT: typedesc[T],
      size: static isize
      ): typedesc =
   ## size is in bits
   when size == 64: i64
   elif size == 32: i32
   elif size == 16: i16
   elif size == 8: i8
   else: {.error: "unhandled size: " & $size.}

template with_size*
      [T: SomeUnsignedInt](
      PT: typedesc[T],
      size: static isize
      ): typedesc =
   ## size is in bits
   when size == 64: u64
   elif size == 32: u32
   elif size == 16: u16
   elif size == 8: u8
   else: {.error: "unhandled size: " & $size.}

template with_size*
      [T: SomeFloat](
      PT: typedesc[T],
      size: static isize
      ): typedesc =
   ## size is in bits
   when size == 64: f64
   elif size == 32: f32
   else: {.error: "unhandled size: " & $size.}

template with_size*
      [TA: SomeSignedInt; TB](
      PTA: typedesc[TA],
      PTB: typedesc[TB]
      ): typedesc =
   when TB is PtrSized: isize
   else: TA.with_size(size_of(TB) * 8)

template with_size*
      [TA: SomeUnsignedInt; TB](
      PTA: typedesc[TA],
      PTB: typedesc[TB],
      ): typedesc =
   when TB is PtrSized: usize
   else: TA.with_size(size_of(TB) * 8)

template with_size*
      [TA: SomeFloat; TB](
      PTA: typedesc[TA],
      PTB: typedesc[TB]
      ): typedesc =
   TA.with_size(size_of(TB) * 8)

template to_signed*[T: SomeNumber](PT: typedesc[T]): typedesc =
   int.with_size(PT)

template to_unsigned*[T: SomeNumber](PT: typedesc[T]): typedesc =
   uint.with_size(PT)

template to_float*[T: SomeNumber](PT: typedesc[T]): typedesc =
   float.with_size(PT)
