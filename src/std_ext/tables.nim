import
   ../std_ext,
   std/tables as sys_tables

export
   sys_tables

proc init*[K, V](cap = default_initial_size): Table[K, V] {.attach, inline.} =
   result = init_Table[K, V](right_size(cap))

proc init*[K, V](xs: openarray[(K, V)]): Table[K, V] {.attach, inline.} =
   result = Table[K, V].init(xs.len)
   for (k, v) in xs:
      result[k] = v

proc init[K](cap = default_initial_size): CountTable[K] {.attach, inline.} =
   result = new_CountTable(cap)
