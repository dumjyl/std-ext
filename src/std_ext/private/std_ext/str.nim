proc init*(Self: type[string], len: Natural = 0.Natural): string {.inline.} =
   ## Return a new ``string`` with length ``len`` of zero initialized elements.
   result = new_string(len)

proc of_cap*(Self: type[string], cap: Natural): string {.inline.} =
   ## Return a new ``string`` with a capacity ``cap``.
   result = new_string_of_cap(cap)
