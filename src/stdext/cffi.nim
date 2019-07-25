import
  ./typetraits,
  ./macros,
  ./anon

type
  CError* = object of CatchableError

macro emit*(emits: varargs[untyped]): untyped =
  result =
    nnkPragma.tree(
      nnkExprColonExpr.tree(
        id"emit",
        nnkBracket.tree(emits)))

proc classAccessSpec(ns: Node; defs: var seq[Node]) =
  ns.needsKind(nnkStmtList)
  for n in ns:
    case n.kind:
    of nnkCall:
      let f = callStmtField(n)
      defs.add(genDefTyp(f.lhs, f.rhs))
    of nnkProcDef: discard
    else: unexpNode(n)

macro class*(name, body: untyped): untyped =
  when not defined(cpp):
    error("class macro only supported for c++ backend", name)
  var privDefs, pubDefs: seq[Node]
  for spec in body:
    spec.needsKind(nnkCall)
    spec.needsLen(2)
    spec[0].needsId("public", "private")
    spec[1].needsKind(nnkStmtList)
    if `id==`(spec[0], "private"):
      classAccessSpec(spec[1], privDefs)
    else:
      classAccessSpec(spec[1], pubDefs)
  let strName = strVal(name)
  result = quote do: emit("class ", `strName`, "{};")
  var fields: seq[Node]
  for def in pubDefs:
    if def.kind == nnkIdentDefs:
      fields.add(makePub(def))
  for def in privDefs:
    if def.kind == nnkIdentDefs:
      fields.add(def)
  result =
    nnkTypeSection.tree(
      nnkTypeDef.tree(
        pubId(name.strVal, [id"importcpp"]),
        empty,
        nnkObjectTy.tree(
          empty,
          empty,
          nnkRecList.tree(fields))))

when isMainModule:
  class Foo:
    private:
      x: int

    public:
      proc Foo(this: ptr Foo): Foo =
        discard

  var x: Foo
  echo x
