import
  ./std_ext

type
  TInit[T] = object
    str: string
    i32: int32
    val: T

proc init*[T](str: string, i32: int32, val: T): TInit[T] {.inits.} =
  result = Self[T](str: str, i32: i32, val: val)

main_proc:
  block_of assert:
    TInit.init("abc", 123'i32, @[1, 2, 3]) == TInit[seq[int]](str: "abc",
                                                              i32: 123.i32,
                                                              val: @[1, 2, 3])
    string.init(5).len == 5
    seq[int].init(5).len == 5
    string.of_cap(5).len == 0
    seq[int].of_cap(5).len == 0
