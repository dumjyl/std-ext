import
  ../stdext,
  ./macros

proc implUnroll[T](n: NimNode; xSym: NimNode; x: T): NimNode =
  result = n
  if `id==`(n, xSym):
    result = newLit(x)
  for i in span(n):
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

templUnroll(int, int, span(xs))
templUnroll(openarray[int], int, xs)
templUnroll(openarray[string], string, xs)

main:
  var sum = 0
  unroll x, @[1, 2, 3], true:
    var y = x * 2
    sum += y
  doAssert(sum == 12)
