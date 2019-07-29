import
  ../stdext,
  ./macros

macro tupled*(T: typedesc, N: static int): typedesc =
  ## Create a tuple of type T with cardinality N.
  result = nnkPar.tree()
  for i in span(N-1):
    result.add(T)

macro ADT(T: untyped): untyped =
  discard

testFn:
  doAssert(int.tupled(3) is (int, int, int))
