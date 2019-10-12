import
   ../../macros

type
   Unit* = tuple
   Some* = distinct Unit
   None* = distinct Unit
   StackRecords* = object|tuple
   Records* = object|ref object|tuple
   Nilable* = ref | ptr | pointer | c_string | c_string_array
   PointerSized* = isize | usize | ptr | pointer # | ref ?
   u8* = uint8
   u16* = uint16
   u32* = uint32
   u64* = uint64
   usize* = uint
   i8* = int8
   i16* = int16
   i32* = int32
   i64* = int64
   isize* = int
   f32* = float32
   f64* = float64
   NU8* = static u8
   NU16* = static u16
   NU32* = static u32
   NU64* = static u64
   NU* = static usize
   NI8* = static i8
   NI16* = static i16
   NI32* = static i32
   NI64* = static i64
   NI* = static isize
   NF32* = static f32
   NF64* = static f64

macro tupled*(T: typedesc, N: static int): typedesc =
   ## Create a tuple of type T with cardinality N.
   result = nnk_par.init()
   for i in 0 ..< N:
      result.add(T)

template no_ptr*[T](PT: typedesc[ptr T]): typedesc =
   ## Get the inner type of a ptr.
   T

template no_ref*[T](PT: typedesc[ref T]): typedesc =
   ## Get the inner type of a ref.
   T

template is_signed*[T: SomeNumber](PT: typedesc[T]): bool =
   ## Check if a numeric type is signed.
   when T is SomeSignedInt or T is SomeFloat: true
   elif T is SomeUnsignedInt: false
   else: {.error: "unhandled type: " & $T.}

template is_unsigned*[T: SomeNumber](PT: typedesc[T]): bool =
   ## Check if a numeric type is unsigned.
   not is_signed(PT)

template with_size*
      [T: SomeSignedInt](
      PT: typedesc[T],
      size: static isize
      ): typedesc =
   ## ``size`` is in bits.
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
   ## ``size`` is in bits.
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
   ## ``size`` is in bits.
   when size == 64: f64
   elif size == 32: f32
   else: {.error: "unhandled size: " & $size.}

template with_size*
      [TA: SomeSignedInt; TB](
      PTA: typedesc[TA],
      PTB: typedesc[TB]
      ): typedesc =
   when TB is PointerSized: isize
   else: TA.with_size(size_of(TB) * 8)

template with_size*
      [TA: SomeUnsignedInt; TB](
      PTA: typedesc[TA],
      PTB: typedesc[TB],
      ): typedesc =
   when TB is PointerSized: usize
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

proc impl_holes(T: NimNode): seq[Slice[BiggestInt]] =
   let typ = T.typ
   typ.needs_kind(nnk_enum_ty)
   var last = typ[1].int_val
   for i in 2 ..< typ.len:
      let cur = typ[i].int_val
      if cur != last + 1:
         result.add(last + 1 .. cur - 1)
      last = cur

macro holes*(T: typedesc[enum]): untyped =
   ## Return holes of an `enum` in the form ``array[N, Slice[BiggestInt]]``.
   result = nnk_bracket.init()
   for hole in impl_holes(T):
      result.add(gen_lit(hole))
   result = gen_call(
      gen_array_typ(result.len, get_typ_inst(Slice[BiggestInt])),
      result)

macro has_holes*(T: typedesc[enum]): bool =
   ## Return wether a `enum` has holes.
   result = gen_lit(impl_holes(T).len != 0)

macro len*(T: typedesc[enum]): isize =
   ## Return the length of an enum. Does not include holes.
   T.typ.needs_kind(nnk_enum_ty)
   result = gen_lit(T.typ.len - 1)
