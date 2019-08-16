import
  ./modes,
  ../../meta

proc `$`*(x: ref|ptr): string =
  result = $type_of(x)
  if x == nil:
    result &= "(nil)"
  else:
    when type_of(x[]) is object:
      result &= system.`$`(x[])
    else:
      result &= "(" & $x[] & ")"

proc `$`(x: object): string =
  # TODO: system.`$` creates ambiguity.
  result = $type_of(x) & system.`$`(x)

test:
  type
    Obj = object
      str: string
      i32: int32
    RefObj = ref Obj
    AnonRefObj = ref object
      str: string
      i32: int32

test_proc:
  block_of assert:
    $Obj(str: "obj str", i32: 3) == "Obj(str: \"obj str\", i32: 3)"
    $RefObj(str: "ref obj str", i32: 7) ==
              "RefObj(str: \"ref obj str\", i32: 7)"
    $AnonRefObj(str: "anon ref obj str", i32: 53) ==
              "AnonRefObj(str: \"anon ref obj str\", i32: 53)"
    $default(ptr int) == "ptr int(nil)"
    $default(AnonRefObj) == "AnonRefObj(nil)"
