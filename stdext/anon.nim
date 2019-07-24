import
  ./strutils,
  ./macros

{.experimental: "dotOperators".}

type
  Anonymous = object

const
  _* = Anonymous()
  fieldLookup = CacheTable"stdext/anon.fieldLookup"

macro Enum*(fields: varargs[untyped]): untyped =
  var name = "Enum"
  for f in fields:
    name &= f.str
  result = nnkStmtList.tree(
    genTypeDef(id(name), nnkEnumTy.tree(empty & sons(fields))),
    id(name))
  for f in fields:
    fieldLookup[noStyle(f.str)] = result

proc findEnumType(fieldStr: string): NimNode =
  for field, enumType in fieldLookup:
    if noStyle(fieldStr) == field:
      return enumType
  error("anonymous field " & fieldStr & " not found")

macro `.`*(_: Anonymous; field: untyped): untyped =
  result = nnkDotExpr.tree(findEnumType(field.str), field)

when isMainModule:
  var x: Enum(NoInit, PartialInit, FullInit)
  x = FullInit
  assert(x == FullInit)
  assert typeof(x) is EnumNoInitPartialInitFullInit
