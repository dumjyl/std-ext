import
  ../stdext,
  ./macros

macro argTyp*(fn: typed; i: static[int]): untyped =
  fn.needsKind(nnkSym)
  let typ = fn.typ
  typ.needsKind(ntyProc)
  result = typ[i+1]
