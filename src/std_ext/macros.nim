import
   std/strformat,
   std/strutils,
   std/macros as sys_macros,
   std/macrocache

export
   sys_macros except `$`, emit, copy_nim_tree, expect_kind, expect_len,
                     expect_min_len

export
   macrocache

type
   Node* = NimNode
   NodeKind* = NimNodeKind
   NodeKinds* = set[NodeKind]
   TypeKind* = NimTypeKind
   TypeKinds* = set[TypeKind]
   SymKind* = NimSymKind
   SymKinds* = set[SymKind]

const
   nnk_sym_like_kinds* = {nnk_ident, nnk_sym, nnk_open_sym_choice,
                          nnk_closed_sym_choice}

proc `$`*(n: Node): string =
   let lit = "Literal:\n" & repr(n).indent(2)
   let tree = "Tree:\n" & tree_repr(n).indent(2)
   result = "Node:\n" & (lit & "\n" & tree).indent(2)

proc init*(Self: typedesc[NimNode], kind: NodeKind): Node =
   result = new_NimNode(kind)

proc init*(kind: NodeKind, sons: varargs[Node]): Node =
   result = Node.init(kind)
   for son in sons:
      result.add(son)

proc init*(kind: SymKind, name: string): Node =
   result = gen_sym(kind, name)

proc tree*(kind: NodeKind, sons: varargs[Node]): Node =
   result = kind.init(sons)

proc node*(kind: NodeKind): Node =
   result = kind.init()

proc node*(kind: NodeKind, val: string): Node =
   result = kind.init()
   result.str_val = val

proc node*(kind: NodeKind, val: int): Node =
   result = kind.init()
   result.int_val = val

proc id*(name: string, public = false, pragmas: openarray[Node] = [],
         backtick = false): Node =
   result = ident(name)
   if backtick:
      result = nnk_acc_quoted.init(result)
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

proc typ_kind*(n: Node): TypeKind =
   result = type_kind(n)

proc skip*(n: Node, kind: NodeKind, pos: int|BackwardsIndex = ^1): Node =
   result = n
   while result.len != 0 and result.kind == kind:
      result = result[pos]

proc skip*(n: Node, kinds: NodeKinds, pos: int|BackwardsIndex = ^1): Node =
   result = n
   while result.len != 0 and result.kind in kinds:
      result = result[pos]

proc skip*(n: Node, kind: TypeKind, pos: int|BackwardsIndex = ^1): Node =
   result = n
   while result.len != 0 and result.typ_kind == kind:
      result = result[pos]

proc skip*(n: Node, kinds: TypeKinds, pos: int|BackwardsIndex = ^1): Node =
   result = n
   while result.len != 0 and result.typ_kind in kinds:
      result = result[pos]

proc typ*(n: Node, skip_typedesc = true): Node =
   result = get_type(n)
   if skip_typedesc:
      result = result.skip(nty_typedesc)

proc typ_inst*(n: Node, skip_typedesc = true): Node =
   result = get_type_inst(n)
   if skip_typedesc:
      result = result.skip(nty_typedesc)

proc typ_impl*(n: Node, skip_typedesc = true): Node =
   result = get_type_impl(n)
   if skip_typedesc:
      result = result.skip(nty_typedesc)

proc impl*(n: Node): Node =
   result = get_impl(n)

proc str*(n: Node): string =
   case n.kind
   of nnk_acc_quoted, nnk_closed_sym_choice, nnk_open_sym_choice:
      result = n[0].str
   else:
      result = str_val(n)

proc `id==`*(a: Node, b: string): bool =
   result = eq_ident(a, b)

proc `id!=`*(a: Node, b: string): bool =
   result = not eq_ident(a, b)

proc `id==`*(a: Node, b: Node): bool =
   result = eq_ident(a, b)

proc `id!=`*(a: Node, b: Node): bool =
   result = not eq_ident(a, b)

proc `type==`*(a: Node, b: Node): bool =
   result = same_type(a, b)

proc `type!=`*(a: Node, b: Node): bool =
   result = not same_type(a, b)

proc `type==`*(a: Node, b: typedesc): bool =
   result = `type==`(a, get_type(b))

proc `type!=`*(a: Node, b: typedesc): bool =
   result = not `type==`(a, get_type(b))

proc needs_len*(n: Node, len: int) =
   if n.len != len:
      error(&"bad node len. needs<{len}> got<{n.len}>\n{n}", n)

proc needs_kind*(n: Node; kind: NodeKind) =
   if n.kind != kind:
      error(&"bad node kind. needs<{kind}> got<{n.kind}>\n{n}", n)

proc needs_kind*(n: Node; kinds: set[NodeKind]) =
   if n.kind notin kinds:
      error(&"bad node kind. needs<{kinds}> got<{n.kind}>\n{n}", n)

proc needs_kind*(n: Node; kind: TypeKind) =
   if n.typ_kind != kind:
      error(&"bad node type kind. needs<{kind}> got<{n.typeKind}>\n{n}", n)

proc needs_id*(n: Node; idents: varargs[string]) =
   n.needs_kind(nnk_ident)
   for ident in idents:
      if `id==`(n, ident):
         return
   error(&"bad node ident. needs<{idents}> got<{n.strVal}>\n{n}", n)

proc unexp_node*(n: Node) =
   error(&"unexpected node:\n{n}", n)

proc low*(n: Node): int =
   result = 0

proc high*(n: Node): int =
   result = n.len - 1

proc gen_def*(name: Node, typ: Node, val: Node): Node =
   result = nnk_ident_defs.tree(name, typ, val)

proc gen_def_id*(name: Node): Node =
   result = nnk_ident_defs.tree(name, empty, empty)

proc gen_def_val*(name: Node, val: Node): Node =
   result = nnk_ident_defs.tree(name, empty, val)

proc gen_def_typ*(name: Node, typ: Node): Node =
   result = nnk_ident_defs.tree(name, typ, empty)

proc gen_lit*(val: string): Node =
   result = nnk_str_lit.node(val)

proc gen_lit*(val: int): Node =
   result = nnk_int_lit.node(val)

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

proc gen_colon*(a: Node, b: Node): Node =
   result = nnk_expr_colon_expr.init(a, b)

proc gen_dot*(a: Node, b: Node): Node =
   result = nnk_dot_expr.init(a, b)

proc gen_dot*(a: Node, b: string): Node =
   result = nnk_dot_expr.init(a, id(b))

proc gen_index*(x: Node, idxs: varargs[Node]): Node =
   result = nnk_bracket_expr.init(x)
   result.add(idxs)

proc gen_typ*[T: typedesc](TArg: typedesc[T], InnerT: Node): Node =
   nnk_bracket_expr.init(id"typedesc", InnerT)

proc elem_typ*(n: Node): Node =
   case n.typ_kind:
   of nty_array:
      result = n[2]
   of nty_sequence:
      result = n[1]
   of nty_typedesc:
      result = n[1]
   else:
      error("elem_typ unhandled case: " & $n.typ_kind, n)

proc ord_low*(n: Node): BiggestInt =
   case n.typ_kind:
   of nty_array:
      result = ord_low(n[1])
   of nty_range:
      result = n[1].int_val
   else:
      error("ord_low unhandled case: " & $n.typ_kind, n)

proc ord_high*(n: Node): BiggestInt =
   case n.typ_kind:
   of nty_array:
      result = ord_high(n[1])
   of nty_range:
      result = n[2].int_val
   else:
      error("ord_high unhandled case: " & $n.typ_kind, n)

proc ord_len*(n: Node): BiggestInt =
   result = ord_high(n) - ord_low(n) + 1

proc unalias*(stmts: Node, expr: Node, name: string): Node =
   if expr.kind in {nnk_ident, nnk_sym, nnkCharLit..nnkFloat128Lit}:
      result = expr
   else:
      result = nsk_var.init(name)
      stmts.add(gen_var_val(result, expr))

proc gen_stmts*(stmts: varargs[Node]): Node =
   result = nnk_stmt_list.init(stmts)

proc gen_block*(n: Node): Node =
   result = nnk_block_stmt.init(empty, n)

proc gen_proc*(
      name: Node,
      frmls: openarray[Node],
      ret: Node,
      gnrcs: openarray[Node] = [],
      stmts = gen_stmts(),
      prgms: openarray[Node] = [],
      kind = nnk_proc_def,
      ): Node =
   result = kind.init(
      name,
      empty,
      nnk_generic_params.init(gnrcs),
      nnk_formal_params.init(ret & @frmls),
      if prgms.len > 1: nnk_pragma.init(prgms) else: empty,
      empty,
      stmts)

proc gen_gnrc*(args: varargs[Node]): Node =
   result = nnk_bracket_expr.init(args)

proc generic_params*(fn: Node): Node =
   fn.needs_kind(RoutineNodes)
   result = fn[2]

proc `generic_params=`*(fn: Node, params: Node) =
   fn.needs_kind(RoutineNodes)
   fn[2] = params

proc def_syms*(ident_def: Node): seq[Node] =
   ident_def.needs_kind(nnk_ident_defs)
   for i in 0 ..< ident_def.len - 2:
      result.add(ident_def[i])

iterator field_syms*(n: Node): Node =
   ## case objects currently unsupported.
   let n = n.skip({nnk_type_def, nnk_object_ty, nnk_ref_ty, nnk_ptr_ty})
   n.needs_kind(nnk_rec_list)
   for f in n:
      for sym in def_syms(f):
         yield sym

proc gen_constr*(typ: Node, inits: varargs[Node]): Node =
   result = nnk_obj_constr.init(typ)
   result.add(inits)

proc record_impl*(n: Node): Node =
   result = n.typ_inst.skip(nnk_bracket_expr, pos = 0).impl
