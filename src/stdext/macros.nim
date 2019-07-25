import
  ../stdext,
  std/strformat,
  std/strutils,
  std/sets,
  std/macros as sysmacros,
  std/macrocache

export
  sysmacros except `$`, emit, copyNimTree

export
  macrocache

type
  Node* = NimNode
  NodeKind* = NimNodeKind
  TypeKind* = NimTypeKind

proc `$`*(n: Node): string =
  let lit = "Literal:\n" & repr(n).indent(2)
  let tree = "Tree:\n" & treeRepr(n).indent(2)
  result = "NimNode:\n" & (lit & "\n" & tree).indent(2)

proc tree*(kind: NodeKind; sons: varargs[Node]): Node =
  result = newNimNode(kind)
  for son in sons:
    result.add(son)

proc node*(kind: NodeKind): Node =
  result = newNimNode(kind)

proc id*(name: string; public = false;
         pragmas: openarray[Node] = []): Node =
  result = ident(name)

proc pubId*(name: string; pragmas: openarray[Node] = []): Node =
  result = id(name, true, pragmas)

template empty*: Node =
  nnkEmpty.node()

macro dump*(body: untyped): untyped =
  echo body

macro dumpTyped*(body: typed): untyped =
  echo body

proc genTypeDef*(name, def: Node): Node =
  result =
    nnkTypeSection.tree(
      nnkTypeDef.tree(
        name,
        empty,
        def))

proc sons*(n: Node): seq[Node] =
  for son in n:
    result.add(son)

proc typ*(n: Node): Node =
  result = getType(n)

proc str*(n: Node): string =
  result = strVal(n)

proc `id==`*(a: NimNode; b: string): bool =
  result = eqIdent(a, b)

proc `id!=`*(a: NimNode; b: string): bool =
  result = not eqIdent(a, b)

proc `id==`*(a: NimNode; b: NimNode): bool =
  result = eqIdent(a, b)

proc `id!=`*(a: NimNode; b: NimNode): bool =
  result = not eqIdent(a, b)

proc needsLen*(n: Node; len: int) =
  if n.len != len:
    error(&"bad node len. needs<{len}> got<{n.len}>\n{n}")

proc needsKind*(n: Node; kind: NodeKind) =
  if n.kind != kind:
    error(&"bad node kind. needs<{kind}> got<{n.kind}>\n{n}")

proc needsKind*(n: Node; kind: TypeKind) =
  if n.typeKind != kind:
    error(&"bad node type kind. needs<{kind}> got<{n.typeKind}>\n{n}")

proc needsId*(n: Node; idents: varargs[string]) =
  n.needsKind(nnkIdent)
  for ident in idents:
    if `id==`(n, ident):
      return
  error(&"bad node ident. needs<{idents}> got<{n.strVal}>\n{n}")

proc copyTree*(n: Node): Node =
  result = copyNimTree(n)

proc genBlkStmts*(stmts: varargs[NimNode]): NimNode =
  result = nnkBlockStmt.tree(empty, nnkStmtList.tree(stmts))

proc low*(n: Node): int =
  result = 0

proc high*(n: Node): int =
  result = n.len - 1
