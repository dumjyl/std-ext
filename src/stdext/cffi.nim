import
  ./typetraits,
  ./macros,
  ./anon,
  ./os

type
  CError* = object of CatchableError

macro emit*(emits: varargs[untyped]): untyped =
  result = nnkBracket.tree()
  if emits.kind == nnkArglist:
    for emit in emits:
      result.add(emit)
  else:
    unexpNode(emits)
  result =
    nnkPragma.tree(
      nnkExprColonExpr.tree(
        id"emit",
        result))
