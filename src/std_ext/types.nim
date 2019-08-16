import
  ../std_ext,
  ./macros

macro tupled*(T: typedesc, N: static int): typedesc =
  ## Create a tuple of type T with cardinality N.
  result = nnk_par.init()
  for i in span(N):
    result.add(T)

macro ADT(T: untyped): untyped =
  discard
