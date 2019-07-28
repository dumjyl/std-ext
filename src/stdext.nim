from sugar import dump
from strutils import split

export
  dump

#[
  TODO: finish random
  TODO: finish cffi/str
]#

proc `$`*(x: ref|ptr): string =
  result = $typeof(x)
  if x == nil:
    result &= "(nil)"
  else:
    when typeof(x[]) is object:
      result &= system.`$`(x[])
    else:
      result &= "(" & $x[] & ")"

proc `$`(x: object): string =
  result = $typeof(x) & system.`$`(x)

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

template main*(body: untyped) =
  when isMainModule:
    proc implMain =
      body
    implMain()

main:
  type
    Obj = object
      str: string
      i32: int32
    RefObj = ref Obj
    AnonRefObj = ref object
      str: string
      i32: int32

  doAssert($Obj(str: "obj str", i32: 3) == "Obj(str: \"obj str\", i32: 3)")
  doAssert($RefObj(str: "ref obj str", i32: 7) ==
           "RefObj(str: \"ref obj str\", i32: 7)")
  doAssert($AnonRefObj(str: "anon ref obj str", i32: 53) ==
           "AnonRefObj(str: \"anon ref obj str\", i32: 53)")
  doAssert($default(ptr int) == "ptr int(nil)")
  doAssert($default(AnonRefObj) == "AnonRefObj(nil)")
