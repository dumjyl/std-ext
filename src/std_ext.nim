import
  ./std_ext/meta

from sugar import dump
from strutils import split

export
  dump

import
  std_ext/private/std_ext/[initializers, dollars, errors, type_traits,
                           modes]

export
  initializers,
  errors,
  dollars,
  type_traits,
  modes,
  meta

type
  Unit* = tuple
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

template span*(n: int): untyped =
  0 ..< n

template span*(x: untyped): untyped =
  low(x) .. high(x)

proc low*[T: uint|uint32|uint64](x: typedesc[T]): T =
  when size_of(T) == 8:
    result = cast[T](0'i64)
  elif size_of(T) == 4:
    result = cast[T](0'i32)
  else:
    {.error: "unsupported bitsize for low(uint(|32|64))".}

proc high*[T: uint|uint32|uint64](x: typedesc[T]): T =
  when size_of(T) == 8:
    result = cast[T](-1'i64)
  elif size_of(T) == 4:
    result = cast[T](-1'i32)
  else:
    {.error: "unsupported bitsize for high(uint(|32|64))".}

template loop*(stmts: untyped): untyped =
  while true:
    stmts
