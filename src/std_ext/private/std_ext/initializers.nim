import
   ./attachs

proc init*(len: Natural = 0.Natural): string {.attach, inline.} =
   result = new_string(len)

proc init*(self: var string, len: Natural = 0.Natural) {.inline.} =
   self = string.init(len)

proc of_cap*(cap: Natural): string {.attach, inline.} =
   result = new_string_of_cap(cap)

proc init*[T](len: Natural = 0.Natural): seq[T] {.attach, inline.} =
   result = new_seq[T](len)

proc init*[T](self: var seq[T], len: Natural = 0.Natural) {.inline.} =
   self = seq[T].init(len)

proc of_cap*[T](cap: Natural): seq[T] {.attach, inline.} =
   result = new_seq_of_cap[T](cap)
