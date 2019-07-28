import
  ../stdext,
  ./macros

template noptr*(T: typedesc[ref|ptr]): typedesc =
  ## Remove a single ptr/ref indirection from a typedesc
  typeof(default(T)[])

macro argTyp*(fn: typed; i: static[int]): untyped =
  fn.needsKind(nnkSym)
  let typ = fn.typ
  typ.needsKind(ntyProc)
  result = typ[i+1]

main:
  assert(noptr(ptr int) is int)
  assert(noptr(ref seq[float]) is seq[float])
