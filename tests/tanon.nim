import
  ./std_ext,
  ./std_ext/anon

proc foo(kind: `enum`(*KA, KB, KC)): int =
  result = ord(kind)

main_proc:
  var x: `enum`(NoInit, PartialInit, FullInit)
  x = FullInit
  block_of assert:
    x == FullInit
    type_of(x) is EnumNoInitPartialInitFullInit
    foo(_.KB) == 1
