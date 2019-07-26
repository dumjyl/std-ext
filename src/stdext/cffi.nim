import
  ./typetraits,
  ./macros,
  ./anon,
  ./os

type
  CError* = object of CatchableError

macro emit*(emits: varargs[untyped]): untyped =
  result = nnkBracket.tree()
  if emits.kind == nnkArglist:
    for emit in emits:
      result.add(emit)
  else:
    unexpNode(emits)
  result =
    nnkPragma.tree(
      nnkExprColonExpr.tree(
        id"emit",
        result))

proc classAccessSpec(ns: Node; defs: var seq[Node]) =
  ns.needsKind(nnkStmtList)
  for n in ns:
    case n.kind:
    of nnkCall:
      let f = callStmtField(n)
      defs.add(genDefTyp(f.lhs, f.rhs))
    of nnkProcDef:
      discard
    else:
      unexpNode(n)

proc cppFileName(n: Node): string =
  let f = lineInfoObj(n).filename.splitFile
  result = f.name & f.ext & ".cpp"

macro class*(name, body: untyped): untyped =
  when not defined(cpp):
    error("class macro only supported for c++ backend", name)
  var privateDefs, publicDefs: seq[Node]
  for spec in body:
    spec.needsKind(nnkCall)
    spec.needsLen(2)
    spec[0].needsId("public", "private")
    spec[1].needsKind(nnkStmtList)
    if `id==`(spec[0], "private"):
      classAccessSpec(spec[1], privateDefs)
    else:
      classAccessSpec(spec[1], publicDefs)
  
  var fields: seq[Node]
  for def in publicDefs:
    if def.kind == nnkIdentDefs:
      fields.add(makePublic(def))
  for def in privateDefs:
    if def.kind == nnkIdentDefs:
      fields.add(def)
  let strName = name.str
  let header = genLit(cppFileName(name))
  let once = quote do: emit("/*INCLUDESECTION*/\n", "#pragma once")
  let typ = quote do: emit("/*TYPESECTION*/\n", "class ", `strName`, "{};")
  result =
    nnkStmtList.tree(
      once,
      typ,
      nnkTypeSection.tree(
        nnkTypeDef.tree(
          publicId(name.str, [id"importcpp", `gen@:@`(id"header", header)]),
          empty,
          nnkObjectTy.tree(
            empty,
            empty,
            nnkRecList.tree(fields)))))

when isMainModule:
  class Foo:
    private:
      x: int

    public:
      proc Foo(this: ptr Foo): Foo =
        discard

  var x: Foo
  echo x
