import
   ../../macros

type
   Unit* = tuple[]
   Some* = distinct Unit
   None* = distinct Unit
   StackRecords* = object|tuple
   Records* = object|ref object|tuple
   Nilable* = ref | ptr | pointer | c_string | c_string_array
   PointerSized* = isize | usize | ptr | pointer | ref
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
   c_usize* {.import_c: "size_t".} = usize

template type_of_or_void*(expr: untyped): typedesc =
   ## Return the type of ``expr`` or ``void`` on error.
   when compiles(type_of(expr)):
      type_of(expr)
   else:
      void

macro tupled*(T: typedesc, N: static int): typedesc =
   ## Create a tuple of type T with cardinality N.
   result = nnk_par.init()
   for i in 0 ..< N:
      result.add(T)

template deref*[T](PT: typedesc[ptr T]): typedesc =
   ## Get the inner type of a ptr.
   T

template deref*[T](PT: typedesc[ref T]): typedesc =
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
   if result.len == 0:
      result = gen_call(
         gen_array_typ(result.len, typ_inst(Slice[BiggestInt])),
         result)

macro has_holes*(T: typedesc[enum]): bool =
   ## Return wether a `enum` has holes.
   result = gen_lit(impl_holes(T).len != 0)

macro len*(T: typedesc[enum]): isize =
   ## Return the length of an enum. Does not include holes.
   T.typ.needs_kind(nnk_enum_ty)
   result = gen_lit(T.typ.len - 1)
