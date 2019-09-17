import
   ../std_ext,
   std/sets as sys_sets

export
   sys_sets

type
   Set*[T] = HashSet[T]

proc init*[T](cap = default_initial_size): Set[T] {.attach, inline.} =
   result = init_HashSet[T](right_size(cap))

proc init*[T](xs: openarray[T]): Set[T] {.attach, inline.} =
   result = Set[T].init()
   for x in xs:
      result.incl(x)
