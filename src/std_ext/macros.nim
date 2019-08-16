import
  std/strformat,
  std/strutils,
  std/sets,
  std/macros as sysmacros,
  std/macrocache

export
  sysmacros except `$`, emit, copy_nim_tree, expect_kind, expect_len,
                   expect_min_len

export
  macrocache

type
  Node* = NimNode
  NodeKind* = NimNodeKind
  TypeKind* = NimTypeKind
  SymKind* = NimSymKind

const nnk_sym_like_kinds* = {nnk_ident, nnk_sym, nnk_open_sym_choice,
                             nnk_closed_sym_choice}

proc `$`*(n: Node): string =
  let lit = "Literal:\n" & repr(n).indent(2)
  let tree = "Tree:\n" & tree_repr(n).indent(2)
  result = "NimNode:\n" & (lit & "\n" & tree).indent(2)

proc init*(_: typedesc[NimNode], kind: NodeKind): Node =
  result = new_NimNode(kind)

proc init*(kind: NodeKind, sons: varargs[Node]): Node =
  result = Node.init(kind)
  for son in sons:
    result.add(son)

proc tree*(kind: NodeKind, sons: varargs[Node]): Node =
  result = kind.init(sons)

proc node*(kind: NodeKind): Node =
  result = kind.init()

proc node*(kind: NodeKind; str: string): Node =
  result = kind.init()
  result.str_val = str

proc id*(name: string, public = false, pragmas: openarray[Node] = []): Node =
  result = ident(name)
  if public:
    result = postfix(result, "*")
  if pragmas.len > 0:
    result = nnk_pragma_expr.tree(result, nnk_pragma.tree(pragmas))

proc public_id*(name: string, pragmas: openarray[Node] = []): Node =
  result = id(name, true, pragmas)

template empty*: Node =
  nnk_empty.init()

macro dump_ast*(body: untyped): untyped =
  echo body

macro dump_typed_ast*(body: typed): untyped =
  echo body

proc gen_type_def*(name: Node, def: Node): Node =
  result =
    nnk_type_section.tree(
      nnk_type_def.tree(
        name,
        empty,
        def))

proc sons*(n: Node): seq[Node] =
  for son in n:
    result.add(son)

proc typ*(n: Node): Node =
  result = get_type(n)

proc str*(n: Node): string =
  result = str_val(n)

proc `id==`*(a: Node, b: string): bool =
  result = eq_ident(a, b)

proc `id!=`*(a: Node, b: string): bool =
  result = not eq_ident(a, b)

proc `id==`*(a: Node, b: Node): bool =
  result = eq_ident(a, b)

proc `id!=`*(a: Node, b: Node): bool =
  result = not eq_ident(a, b)

proc needs_len*(n: Node, len: int) =
  if n.len != len:
    error(&"bad node len. needs<{len}> got<{n.len}>\n{n}")

proc needs_kind*(n: Node; kind: NodeKind) =
  if n.kind != kind:
    error(&"bad node kind. needs<{kind}> got<{n.kind}>\n{n}")

proc needs_kind*(n: Node; kinds: set[NodeKind]) =
  if n.kind notin kinds:
    error(&"bad node kind. needs<{kinds}> got<{n.kind}>\n{n}")

proc needs_kind*(n: Node; kind: TypeKind) =
  if n.type_kind != kind:
    error(&"bad node type kind. needs<{kind}> got<{n.typeKind}>\n{n}")

proc needs_id*(n: Node; idents: varargs[string]) =
  n.needs_kind(nnk_ident)
  for ident in idents:
    if `id==`(n, ident):
      return
  error(&"bad node ident. needs<{idents}> got<{n.strVal}>\n{n}")

proc unexp_node*(n: Node) =
  error(&"unexpected node:\n{n}")

proc gen_blk_stmts*(stmts: varargs[Node]): Node =
  result = nnk_block_stmt.tree(empty, nnk_stmt_list.tree(stmts))

proc low*(n: Node): int =
  result = 0

proc high*(n: Node): int =
  result = n.len - 1

proc gen_def*(name: Node, typ: Node, val: Node): Node =
  result = nnk_ident_defs.tree(name, typ, val)

proc gen_def_val*(name: Node, val: Node): Node =
  result = nnk_ident_defs.tree(name, empty, val)

proc gen_def_typ*(name: Node, typ: Node): Node =
  result = nnk_ident_defs.tree(name, typ, empty)

proc `gen@:@`*(a: Node, b: Node): Node =
  result = nnk_expr_colon_expr.tree(a, b)

proc gen_lit*(str: string): Node =
  result = nnk_str_lit.node(str)

proc call_stmt_field*(n: Node): tuple[lhs: Node, rhs: Node] =
  n.needs_kind(nnk_ident)
  n.needs_len(2)
  n[0].needs_kind(nnk_ident)
  n[1].needs_kind(nnk_stmt_list)
  n[1].needs_len(1)
  result.lhs = n[0]
  result.rhs = n[1][0]

proc make_public*(n: Node): Node =
  result = n
  case n.kind:
  of nnk_ident_defs:
    n[0] = make_public(n[0])
  of nnk_ident:
    result = postfix(n, "*")
  else:
    unexp_node(n)

proc gen_var*(name: Node, typ: Node, val: Node): Node =
  result = nnk_var_section.init(gen_def(name, typ, val))

proc gen_var_val*(name: Node, val: Node): Node =
  result = nnk_var_section.init(gen_def_val(name, val))

proc gen_var_typ*(name: Node, typ: Node): Node =
  result = nnk_var_section.init(gen_def_typ(name, typ))

proc gen_asgn*(a: Node, b: Node): Node =
  result = nnk_asgn.init(a, b)

proc gen_call*(name: Node, args: varargs[Node]): Node =
  result = nnk_call.init(name)
  for arg in args:
    result.add(arg)

proc gen_call*(name: string, args: varargs[Node]): Node =
  result = gen_call(id(name), args)

proc stmt_concat*(a: Node, b: Node): Node =
  result = nnk_stmt_list.init(a, b)
