import
  ../stdext,
  ./macros

proc implUnroll[T](n: NimNode; xSym: NimNode; x: T): NimNode =
  result = n
  if `id==`(n, xSym):
    result = newLit(x)
  for i in span(n):
    n[i] = n[i].implUnroll(xSym, x)

template metaImplUnroll(TOuter, TInner, iter) =
  macro unroll*(xSym: untyped; xs: static TOuter, withBlock: static bool;
                body: untyped): untyped =
    result = nnkStmtList.tree()
    for x in iter:
      let stmts = implUnroll[TInner](copyTree(body), xSym, x)
      if withBlock:
        result.add(genBlkStmts(stmts))
      else:
        result.add(stmts)

metaImplUnroll(int, int, span(xs))
metaImplUnroll(seq[int], int, xs)
metaImplUnroll(seq[string], string, xs)

when isMainModule:
  proc intStrs(n: int): seq[string] =
    for i in 0 ..< n:
      result.add($i & "%")

  unroll y, intStrs(4), true:
    var x = y
    echo x
