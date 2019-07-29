import
  ../stdext,
  ./strutils,
  ./macros

{.experimental: "dotOperators".}

type
  Anonymous = object

const
  _* = Anonymous()
  fieldLookup = CacheTable"stdext/anon.fieldLookup"

macro `enum`*(fields: varargs[untyped]): untyped =
  var name = "Enum"
  var public = false
  if fields[0].kind == nnkPrefix and `id==`(fields[0][0], "*"):
    fields[0] = fields[0][1]
    public = true
  for f in fields:
    f.needsKind(nnkIdent)
    name &= f.str
  result = nnkStmtList.tree(
    genTypeDef(id(name), nnkEnumTy.tree(empty & sons(fields))),
    id(name))
  for f in fields:
    if public:
      fieldLookup[noStyle(f.str)] = result

proc findEnumType(fieldStr: string): Node =
  for field, enumType in fieldLookup:
    if noStyle(fieldStr) == field:
      return enumType
  error("anonymous field " & fieldStr & " not found")

macro `.`*(_: Anonymous; field: untyped): untyped =
  result = nnkDotExpr.tree(findEnumType(field.str), field)

test:
  proc foo(kind: `enum`(*KA, KB, KC)): int =
    result = ord(kind)

testFn:
  var x: `enum`(NoInit, PartialInit, FullInit)
  x = FullInit
  assert(x == FullInit)
  assert typeof(x) is EnumNoInitPartialInitFullInit

  doAssert(foo(_.KB) == 1)
