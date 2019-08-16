import
  ../std_ext

type
  FatPointer* = object
    data*: pointer
    len*: int
  FatPtr*[T] = object
    data*: ptr T
    len*: int

proc `[]`*(fp: FatPointer, idx: int): byte =
  result = cast[ptr UncheckedArray[byte]](fp.data)[idx]

proc low*(fp: FatPointer): int =
  result = 0

proc high*(fp: FatPointer): int =
  result = fp.len - 1

proc `[]`*[T](fp: FatPtr[T], idx: int): T =
  result = cast[ptr UncheckedArray[T]](fp.data)[idx]

proc low*[T](fp: FatPtr[T]): int =
  result = 0

proc high*[T](fp: FatPtr[T]): int =
  result = fp.len - 1

proc to*(fp: FatPointer, T: typedesc[string]): string =
  if fp.data != nil:
    result = string.of_cap(fp.len)
    for i in span(fp):
      result.add(char(fp[i]))
