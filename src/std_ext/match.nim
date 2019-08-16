import ./macros

macro match*(val: typed, branches: varargs[untyped]): untyped =
  echo val
  for branch in branches:
    echo branches