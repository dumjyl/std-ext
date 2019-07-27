import
  ./macros

macro ADT(T: untyped): untyped =
  discard

main:
  type Test = ADT Foo(float, int, string) |
                                      int |
                                    float
