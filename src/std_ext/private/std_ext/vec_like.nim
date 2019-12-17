import
   types

proc init*[T](
      Self: type[seq[T]], len: Natural = 0.Natural): seq[T] {.inline.} =
   ## Return a new ``seq`` with length ``len`` of zero initialized elements.
   result = new_seq[T](len)

proc of_cap*[T](Self: type[seq[T]], cap: Natural): seq[T] {.inline.} =
   ## Return a new ``seq`` with a capacity ``cap``.
   result = new_seq_of_cap[T](cap)

proc `&`*[I0: static isize, I1: static isize, T](
          a: array[I0, T], b: array[I1, T]): array[I0 + I1, T] =
   for i in 0 ..< I0:
      result[i] = a[i]
   for i in 0 ..< I1:
      result[I0 + i] = b[i]

proc `&`*[I: static isize, T](a: array[I, T], b: T): array[I + 1, T] =
   for i in 0 ..< I:
      result[i] = a[i]
   result[I] = b

proc `&`*[I: static isize, T](a: T, b: array[I, T]): array[I + 1, T] =
   result[0] = a
   for i in 0 ..< I:
      result[i+1] = b[i]

proc `&`*[T](a: openarray[T], b: openarray[T]): seq[T] =
   result = seq[T].init(a.len + b.len)
   for i in 0 ..< len(a):
      result[i] = a[i]
   for i in 0 ..< len(b):
      result[a.len + i] = b[i]

proc `&`*[T](a: openarray[T], b: T): seq[T] =
   result = @a
   result.add(b)

proc `&`*[T](a: T, b: openarray[T]): seq[T] =
   result = seq[T].init(b.len + 1)
   for i in 0 ..< len(b):
      result[i+1] = b[i]
