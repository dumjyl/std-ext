import
  ./stdext/[macros, meta]

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
  # TODO: system.`$` creates ambiguity.
  result = $typeof(x) & system.`$`(x)

type
  LowHigh* = concept x
    low(x)
    high(x)

template noptr*[T](PtrT: typedesc[ptr T]): typedesc = T

template noref*[T](RefT: typedesc[ref T]): typedesc = T

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

template main*(stmts: untyped) =
  when isMainModule:
    stmts

template mainFn*(stmts: untyped) =
  main:
    proc implMainFn =
      stmts
    implMainFn()

template test*(stmts: untyped) =
  when isMainModule and defined(testing):
    stmts

template testFn*(stmts: untyped) =
  test:
    proc implTestFn =
      stmts
    implTestFn()

template asserts*(stmts: untyped) =
  # TODO: correct line info
  mapStmts(stmts, assert)

test:
  type
    Obj = object
      str: string
      i32: int32
    RefObj = ref Obj
    AnonRefObj = ref object
      str: string
      i32: int32

testFn:
  asserts:
    $Obj(str: "obj str", i32: 3) == "Obj(str: \"obj str\", i32: 3)"
    $RefObj(str: "ref obj str", i32: 7) ==
              "RefObj(str: \"ref obj str\", i32: 7)"
    $AnonRefObj(str: "anon ref obj str", i32: 53) ==
              "AnonRefObj(str: \"anon ref obj str\", i32: 53)"
    $default(ptr int) == "ptr int(nil)"
    $default(AnonRefObj) == "AnonRefObj(nil)"

    noptr(ptr int) is int
    noref(ref seq[float]) is seq[float]
