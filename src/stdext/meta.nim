import
  ./macros

proc implUnroll[T](n: NimNode; xSym: NimNode; x: T): NimNode =
  result = n
  if `id==`(n, xSym):
    result = newLit(x)
  for i in 0 ..< n.len:
    n[i] = n[i].implUnroll(xSym, x)

template templUnroll(TOuter, TInner, iter) =
  macro unroll*(xSym: untyped; xs: static TOuter, withBlock: static bool;
                body: untyped): untyped =
    result = nnkStmtList.tree()
    for x in iter:
      let stmts = implUnroll[TInner](copy(body), xSym, x)
      if withBlock:
        result.add(genBlkStmts(stmts))
      else:
        result.add(stmts)

templUnroll(int, int, 0 ..< xs)
templUnroll(openarray[int], int, xs)
templUnroll(openarray[string], string, xs)

macro mapStmts*(stmts, op: untyped): untyped =
  stmts.needsKind(nnkStmtList)
  for i in 0 ..< stmts.len:
    stmts[i] = nnkCall.tree(op, stmts[i])
  result = stmts
