from sugar import dump

export
  dump

proc `$`*(x: ref|ptr): string =
    if x != nil:
      result = "ref " & $x[]
    else:
      result = "ref nil"

type
  LowHigh* = concept x
    low(x)
    high(x)

template span*(n: int): untyped =
  0 .. n

template span*(x: LowHigh): untyped =
  low(x) .. high(x)

proc low*[T: uint|uint32|uint64](x: typedesc[T]): T =
  when sizeof(T) == 8: result = cast[T](0'i64)
  elif sizeof(T) == 4: result = cast[T](0'i32)
  else: {.error: "unsupported bitsize for low(uint(|32|64))".}

proc high*[T: uint|uint32|uint64](x: typedesc[T]): T =
  when sizeof(T) == 8: result = cast[T](-1'i64)
  elif sizeof(T) == 4: result = cast[T](-1'i32)
  else: {.error: "unsupported bitsize for high(uint(|32|64))".}
