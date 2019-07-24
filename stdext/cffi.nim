import
  ./typetraits,
  ./macros,
  ./anon

macro emit*(emits: varargs[untyped]): untyped =
  result =
    nnkPragma.tree(
      nnkExprColonExpr.tree(
        id"emit",
        nnkBracket.tree(emits)))

proc semAccessSpec(n: NimNode; privacy: Enum(Private, Public)) =
  echo privacy

macro class*(name: untyped; body: untyped): untyped =
  when not defined(cpp):
    error("class macro only supported for c++ backend", name)
  for spec in body:
    spec.needsKind(nnkCall)
    spec.needsLen(2)
    spec[0].needsId("public", "private")
    spec[1].needsKind(nnkStmtList)
    if spec[0].eqIdent("public"):
      semAccessSpec(spec[1], _.Private)
    else:
      semAccessSpec(spec[1], _.Public)
      # echo Private
      # semAccessSpec(spec[1], Private)

  let strName = strVal(name)
  result = quote do: emit("class ", `strName`, "{};")
  result =
    nnkTypeSection.tree(
      nnkTypeDef.tree(
        pubId(name.strVal, [id"importcpp"]),
        empty,
        nnkObjectTy.tree(
          empty,
          empty,
          empty)))

when isMainModule:
  class Foo:
    private:
      var x: int

    public:
      proc Foo(): Foo {.initializer: [].} =
        discard

  var x: Foo
  echo x
