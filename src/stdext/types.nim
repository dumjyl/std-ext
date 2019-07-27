import
  ./macros

macro ADT(T: untyped): untyped =
  discard

when isMainModule:
  type Test = ADT Foo(float, int, string) |
                                      int |
                                    float
