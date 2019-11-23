import
  ./attachs

proc init*(len: Natural = 0.Natural): string {.attach, inline.} =
   ## Return a new ``string`` with length ``len`` of zero initialized elements.
   result = new_string(len)

proc of_cap*(cap: Natural): string {.attach, inline.} =
   ## Return a new ``string`` with a capacity ``cap``.
   result = new_string_of_cap(cap)
