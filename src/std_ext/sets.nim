import
   ../std_ext,
   std/sets as sys_sets

export
   sys_sets

type
   Set*[T] = HashSet[T]

proc init*[T](
      Self: type[Set[T]],
      cap = default_initial_size
      ): Set[T] {.inline.} =
   result = init_HashSet[T](right_size(cap))

proc init*[T](Self: type[Set[T]], xs: openarray[T]): Set[T] {.inline.} =
   result = Set[T].init()
   for x in xs:
      result.incl(x)
