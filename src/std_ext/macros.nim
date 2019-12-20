import
   std/strformat,
   std/strutils, std/macros as sys_macros,
   std/macrocache
export
   sys_macros except `$`, emit, copy_nim_tree, expect_kind, expect_len,
                     expect_min_len, pragma, `pragma=`

export
   macrocache

type
   NimTypeKinds* = set[NimTypeKind]
   NimSymKinds* = set[NimSymKind]
   NimIndex* = int|BackwardsIndex

const
   nnk_sym_like_kinds* = {nnk_ident, nnk_sym, nnk_open_sym_choice,
                          nnk_closed_sym_choice}

const
   fn_name_pos* = 0
   fn_pragma_pos* = 4

const
   indent_width = 2

proc `$`*(n: NimNode): string =
   ## A dollar function for NimNodes more suited for debgging.
   # TODO: color support
   let lit = "Literal:\n" & repr(n).indent(indent_width)
   let tree = "Tree:\n" & tree_repr(n).indent(indent_width)
   result = "Node:\n" & (lit & "\n" & tree).indent(indent_width)

proc err*(ast: NimNode, msg: string, line_ast: NimNode = nil) =
   let err_msg = msg & ":\n" & ($ast).indent(indent_width)
   error(err_msg, if line_ast == nil: ast else: line_ast)

proc err_ex*(ast: NimNode, msg: string, line_ast: NimNode = nil) =
   let err_line_ast = if line_ast == nil: ast else: line_ast
   var ast_str = repr(ast)
   if ast_str.contains("\n"):
      error(msg & ":\n" & ast_str.indent(indent_width), err_line_ast)
   else:
      error(msg & ": " & ast_str, err_line_ast)

proc unexp_err*(ast: NimNode) =
   ast.err("unexpected node")

proc init*(kind: NimNodeKind, sons: varargs[NimNode]): NimNode =
   result = new_NimNode(kind)
   for son in sons:
      result.add(son)

proc init*(kind: NimSymKind, name: string): NimNode =
   result = gen_sym(kind, name)

proc init*(kind: NimNodeKind, val: string): NimNode =
   result = kind.init()
   result.str_val = val

proc init*(kind: NimNodeKind, val: int): NimNode =
   result = kind.init()
   result.int_val = val

proc id*(
      name: string,
      public = false,
      pragmas: openarray[NimNode] = [],
      backtick = false
      ): NimNode =
   ## Identifer constructor with options for exporting, pragmas, and backtick
   ## quoting.
   result = ident(name)
   if backtick:
      result = nnk_acc_quoted.init(result)
   if public:
      result = postfix(result, "*")
   if pragmas.len > 0:
      result = nnk_pragma_expr.init(result, nnk_pragma.init(pragmas))

proc public_id*(
      name: string,
      pragmas: openarray[NimNode] = [],
      backtick = false
      ): NimNode =
   ## An alias for `id` that is always public.
   result = id(name, true, pragmas, backtick)

template empty*: NimNode =
   ## Empty node constructor.
   nnk_empty.init()

macro dump_ast*(body: untyped): untyped =
   echo body

macro dump_typed_ast*(body: typed): untyped =
   echo body

proc gen_type_def*(name: NimNode, def: NimNode): NimNode =
   ## Generates a type section with a single type definition.
   result =
      nnk_type_section.init(
         nnk_type_def.init(
            name,
            empty,
            def))

proc sons*(n: NimNode): seq[NimNode] =
   ## Return a sequence of the sons of `n`.
   for son in n:
      result.add(son)

proc typ_kind*(n: NimNode): NimTypeKind =
   ## An alias for `macros.type_kind`.
   result = type_kind(n)

proc skip*(n: NimNode, kind: NimNodeKind, pos: NimIndex = ^1): NimNode =
   result = n
   while result.len != 0 and result.kind == kind:
      result = result[pos]

proc skip*(n: NimNode, kinds: NimNodeKinds, pos: NimIndex = ^1): NimNode =
   result = n
   while result.len != 0 and result.kind in kinds:
      result = result[pos]

proc skip*(n: NimNode, kind: NimTypeKind, pos: NimIndex = ^1): NimNode =
   result = n
   while result.len != 0 and result.typ_kind == kind:
      result = result[pos]

proc skip*(n: NimNode, kinds: NimTypeKinds, pos: NimIndex = ^1): NimNode =
   result = n
   while result.len != 0 and result.typ_kind in kinds:
      result = result[pos]

proc typ*(n: NimNode, skip_typedesc = true): NimNode =
   result = get_type(n)
   if skip_typedesc:
      result = result.skip(nty_typedesc)

proc typ_inst*(n: NimNode, skip_typedesc = true): NimNode =
   result = get_type_inst(n)
   if skip_typedesc:
      result = result.skip(nty_typedesc)

proc typ_impl*(n: NimNode, skip_typedesc = true): NimNode =
   result = get_type_impl(n)
   if skip_typedesc:
      result = result.skip(nty_typedesc)

proc typ*(T: typedesc, skip_typedesc = true): NimNode =
   result = get_type(T)
   if skip_typedesc:
      result = result.skip(nty_typedesc)

proc typ_inst*(T: typedesc, skip_typedesc = true): NimNode =
   result = get_type_inst(T)
   if skip_typedesc:
      result = result.skip(nty_typedesc)

proc typ_impl*(T: typedesc, skip_typedesc = true): NimNode =
   result = get_type_impl(T)
   if skip_typedesc:
      result = result.skip(nty_typedesc)

proc impl*(n: NimNode): NimNode =
   result = get_impl(n)

proc `id==`*(a: NimNode, b: string): bool =
   result = eq_ident(a, b)

proc `id!=`*(a: NimNode, b: string): bool =
   result = not eq_ident(a, b)

proc `id==`*(a: NimNode, b: NimNode): bool =
   result = eq_ident(a, b)

proc `id!=`*(a: NimNode, b: NimNode): bool =
   result = not eq_ident(a, b)

proc str*(n: NimNode): string =
   case n.kind
   of nnk_postfix:
      if `id==`(n[0], "*"):
         result = str(n[1])
      else:
         unexp_err(n)
   of nnk_str_lit .. nnk_triple_str_lit, nnk_comment_stmt, nnk_sym, nnk_ident:
      result = n.str_val
   of nnk_open_sym_choice, nnk_closed_sym_choice:
      result = str(n[0])
   of nnk_acc_quoted:
      result = str(n[0])
   else:
      unexp_err(n)

proc `type==`*(a: NimNode, b: NimNode): bool =
   result = same_type(a, b)

proc `type!=`*(a: NimNode, b: NimNode): bool =
   result = not same_type(a, b)

proc `type==`*(a: NimNode, b: typedesc): bool =
   result = `type==`(a, b.typ)

proc `type!=`*(a: NimNode, b: typedesc): bool =
   result = not `type==`(a, b.typ)

proc needs_len*(n: NimNode, len: int) =
   if n.len != len:
      error(&"bad node len. needs<{len}> got<{n.len}>\n{n}", n)

proc needs_len*(n: NimNode, len: Slice[int]) =
   if n.len notin len:
      error(&"bad node len. needs<{len.a} .. {len.b}> got<{n.len}>\n{n}", n)

proc needs_kind*(n: NimNode, kind: NimNodeKind) =
   if n.kind != kind:
      error(&"bad node kind. needs<{kind}> got<{n.kind}>\n{n}", n)

proc needs_kind*(n: NimNode, kinds: set[NimNodeKind]) =
   if n.kind notin kinds:
      error(&"bad node kind. needs<{kinds}> got<{n.kind}>\n{n}", n)

proc needs_kind*(n: NimNode, kind: NimTypeKind) =
   if n.typ_kind != kind:
      error(&"bad node type kind. needs<{kind}> got<{n.typeKind}>\n{n}", n)

proc needs_id*(n: NimNode, idents: varargs[string]) =
   n.needs_kind(nnk_ident)
   for ident in idents:
      if `id==`(n, ident):
         return
   error(&"bad node ident. needs<{idents}> got<{n.strVal}>\n{n}", n)

proc low*(n: NimNode): int =
   result = 0

proc high*(n: NimNode): int =
   result = n.len - 1

proc gen_def*(name: NimNode, typ: NimNode, val: NimNode): NimNode =
   result = nnk_ident_defs.init(name, typ, val)

proc gen_def_id*(name: NimNode): NimNode =
   result = nnk_ident_defs.init(name, empty, empty)

proc gen_def_val*(name: NimNode, val: NimNode): NimNode =
   result = nnk_ident_defs.init(name, empty, val)

proc gen_def_typ*(name: NimNode, typ: NimNode): NimNode =
   result = nnk_ident_defs.init(name, typ, empty)

proc gen_const_def*(name: NimNode, typ: NimNode, val: NimNode): NimNode =
   result = nnk_const_def.init(name, typ, val)

proc gen_const_def_val*(name: NimNode, val: NimNode): NimNode =
   result = nnk_const_def.init(name, empty, val)

proc gen_const_def_typ*(name: NimNode, typ: NimNode): NimNode =
   result = nnk_const_def.init(name, typ, empty)

proc gen_lit*[T](val: T): NimNode =
   ## An alias for `new_lit`
   result = new_lit(val)

proc gen_lit*[T: NimNode](val: T): NimNode =
   ## A nop for generic code.
   result = val

proc call_stmt_field*(n: NimNode): tuple[lhs: NimNode, rhs: NimNode] =
   n.needs_kind(nnk_ident)
   n.needs_len(2)
   n[0].needs_kind(nnk_ident)
   n[1].needs_kind(nnk_stmt_list)
   n[1].needs_len(1)
   result.lhs = n[0]
   result.rhs = n[1][0]

proc make_public*(n: NimNode): NimNode =
   result = n
   case n.kind:
   of nnk_ident_defs:
      n[0] = make_public(n[0])
   of nnk_ident:
      result = postfix(n, "*")
   of nnk_postfix:
      if n.len != 2 or `id!=`(n[0], "*"):
         unexp_err(n)
   else:
      unexp_err(n)

proc gen_var*(name: NimNode, typ: NimNode, val: NimNode): NimNode =
   result = nnk_var_section.init(gen_def(name, typ, val))

proc gen_var_val*(name: NimNode, val: NimNode): NimNode =
   result = nnk_var_section.init(gen_def_val(name, val))

proc gen_var_typ*(name: NimNode, typ: NimNode): NimNode =
   result = nnk_var_section.init(gen_def_typ(name, typ))

proc gen_const*(name: NimNode, typ: NimNode, val: NimNode): NimNode =
   result = nnk_const_section.init(gen_const_def(name, typ, val))

proc gen_const_val*(name: NimNode, val: NimNode): NimNode =
   result = nnk_const_section.init(gen_const_def_val(name, val))

proc gen_const_typ*(name: NimNode, typ: NimNode): NimNode =
   result = nnk_const_section.init(gen_const_def_typ(name, typ))

proc gen_asgn*(a: NimNode, b: NimNode): NimNode =
   result = nnk_asgn.init(a, b)

proc gen_call*(name: NimNode, args: varargs[NimNode]): NimNode =
   result = nnk_call.init(name)
   for arg in args:
      result.add(arg)

proc gen_call*(name: string, args: varargs[NimNode]): NimNode =
   result = gen_call(id(name), args)

proc stmt_concat*(a: NimNode, b: NimNode): NimNode =
   result = nnk_stmt_list.init(a, b)

proc gen_colon*(a: NimNode, b: NimNode): NimNode =
   result = nnk_expr_colon_expr.init(a, b)

proc gen_dot*(a: NimNode, b: NimNode): NimNode =
   result = nnk_dot_expr.init(a, b)

proc gen_dot*(a: NimNode, b: string): NimNode =
   result = nnk_dot_expr.init(a, id(b))

proc gen_index*(x: NimNode, idxs: varargs[NimNode]): NimNode =
   result = nnk_bracket_expr.init(x)
   result.add(idxs)

proc elem_typ*(n: NimNode): NimNode =
   case n.typ_kind:
   of nty_array:
      result = n[2]
   of nty_sequence:
      result = n[1]
   of nty_typedesc:
      result = n[1]
   else:
      error("elem_typ unhandled case: " & $n.typ_kind, n)

proc ord_low*(n: NimNode): BiggestInt =
   case n.typ_kind:
   of nty_array:
      result = ord_low(n[1])
   of nty_range:
      result = n[1].int_val
   else:
      error("ord_low unhandled case: " & $n.typ_kind, n)

proc ord_high*(n: NimNode): BiggestInt =
   case n.typ_kind:
   of nty_array:
      result = ord_high(n[1])
   of nty_range:
      result = n[2].int_val
   else:
      error("ord_high unhandled case: " & $n.typ_kind, n)

proc ord_len*(n: NimNode): BiggestInt =
   result = ord_high(n) - ord_low(n) + 1

proc unalias*(stmts: NimNode, expr: NimNode, name: string): NimNode =
   if expr.kind in {nnk_ident, nnk_sym, nnkCharLit..nnkFloat128Lit}:
      result = expr
   else:
      result = nsk_var.init(name)
      stmts.add(gen_var_val(result, expr))

proc gen_stmts*(stmts: varargs[NimNode]): NimNode =
   result = nnk_stmt_list.init(stmts)

proc gen_block*(n: varargs[NimNode]): NimNode =
   result = nnk_block_stmt.init(empty, gen_stmts(n))

proc gen_block*(n: openarray[NimNode], label: NimNode = empty): NimNode =
   result = nnk_block_stmt.init(label, gen_stmts(n))

proc gen_proc*(
      name: NimNode,
      frmls: openarray[NimNode] = [],
      ret: NimNode = empty,
      gnrcs: openarray[NimNode] = [],
      stmts = gen_stmts(),
      prgms: openarray[NimNode] = [],
      kind = nnk_proc_def,
      ): NimNode =
   result = kind.init(
      name,
      empty,
      nnk_generic_params.init(gnrcs),
      nnk_formal_params.init((if ret != nil: ret else: empty)  & @frmls),
      if prgms.len > 0: nnk_pragma.init(prgms) else: empty,
      empty,
      stmts)

proc gen_gnrc*(ns: varargs[NimNode]): NimNode =
   result = nnk_bracket_expr.init(ns)

proc generic_params*(fn: NimNode): NimNode =
   fn.needs_kind(RoutineNodes)
   result = fn[2]

proc `generic_params=`*(fn: NimNode, params: NimNode) =
   fn.needs_kind(RoutineNodes)
   fn[2] = params

proc def_syms*(n: NimNode): seq[NimNode] =
   case n.kind:
   of nnk_formal_params:
      for param in n[1 .. ^1]:
         result.add(def_syms(param))
   of nnk_ident_defs:
      for i in 0 ..< n.len - 2:
         result.add(n[i])
   else: error("unhandled kind: " & $n)

iterator field_syms*(n: NimNode): NimNode =
   ## Case objects currently unsupported.
   let n = n.skip({nnk_type_def, nnk_object_ty, nnk_ref_ty, nnk_ptr_ty})
   n.needs_kind(nnk_rec_list)
   for f in n:
      for sym in def_syms(f):
         yield sym

proc gen_constr*(typ: NimNode, inits: varargs[NimNode]): NimNode =
   result = nnk_obj_constr.init(typ)
   result.add(inits)

proc record_impl*(n: NimNode): NimNode =
   result = n.typ_inst.skip(nnk_bracket_expr, pos = 0).impl

proc gen_par*(ns: varargs[NimNode]): NimNode =
   result = nnk_par.init(ns)

proc gen_range_typ*[T: SomeNumber](rng: Slice[T]): NimNode =
   result = gen_gnrc(id"range", infix(gen_lit(rng.a), "..", gen_lit(rng.b)))

proc gen_array_typ*(idx: NimNode, typ: NimNode): NimNode =
   result = gen_gnrc(id"array", idx, typ)

proc gen_array_typ*(len: int, typ: NimNode): NimNode =
   result = gen_array_typ(gen_lit(len), typ)

template bind_call*(ident: string, args: varargs[NimNode]): NimNode =
   gen_call(bind_sym(ident)).add(args)

template gen*(stmts: untyped): untyped =
   macro impl_gen: untyped {.gen_sym.} =
      stmts
   impl_gen()

type
   FieldDesc* = tuple
      name: string
      typ: NimNode

iterator field_descs*(T: typedesc): FieldDesc =
   ## Case objects unsupported.
   let typ = typ_impl(T)
   typ.needs_kind(nnk_object_ty)
   typ[2].needs_kind(nnk_rec_list)
   for f in typ[2]:
      f.needs_kind(nnk_ident_defs)
      yield (f[0].str_val, f[1])

proc gen_obj_ty*(
      fields: openarray[NimNode],
      pragmas: openarray[NimNode] = [],
      inherits: NimNode = nil,
      ): NimNode =
   result = nnk_object_ty.init()
   if pragmas.len > 0:
      result.add(nnk_pragma.init())
      result[0].add(pragmas)
   else:
      result.add(empty)
   if inherits != nil:
      result.add(nnk_of_inherit.init(inherits))
   else:
      result.add(empty)
   result.add(nnk_rec_list.init())
   result[2].add(fields)

proc delete*(self: NimNode, i: int, n = 1) =
   ## An alias for `macros.del` due to inconsistent meaning `seq`'s `del`.
   self.del(i, n)

proc set_len*(self: NimNode, len: int, fill = default(NimNode)) =
   ## Set the length of the node.
   ##
   ## Additional nodes added will be `copy(fill)`.
   if len > self.len:
      for _ in 0 ..< len - self.len:
         self.add(copy(fill))
   else:
      self.delete(self.high, self.len - len)

proc pragmas*(ast: NimNode): NimNode =
   case ast.kind:
   of nnk_proc_def:
      result = ast[fn_pragma_pos]
   of nnk_pragma_expr:
      result = ast[1]
   else:
      unexp_err(ast)

proc `pragmas=`*(ast: NimNode, pragma_ast: NimNode) =
   case ast.kind:
   of nnk_proc_def:
      ast[fn_pragma_pos] = pragma_ast
   of nnk_pragma_expr:
      ast[1] = pragma_ast
   else:
      unexp_err(ast)

proc find_pragma(ast: NimNode, name: string): int =
   ast.needs_kind(nnk_pragma)
   for i, pragma in ast:
      case pragma.kind:
      of nnk_ident:
         if `id==`(pragma, name):
            return i
      of nnk_expr_colon_expr:
         if `id==`(pragma[0], name):
            return i
      else: discard
   result = -1

proc has_pragma*(ast: NimNode, name: string): bool =
   case ast.kind:
   of nnk_pragma:
      result = find_pragma(ast, name) != -1
   of nnk_proc_def:
      result = has_pragma(ast.pragmas, name)
   of nnk_pragma_expr:
      result = has_pragma(ast.pragmas, name)
   of nnk_empty:
      result = false
   else:
      unexp_err(ast)

proc get_pragma*(ast: NimNode, name: string, orig_ast: NimNode = nil): NimNode =
   template err = err(if orig_ast == nil: ast else: orig_ast,
                      "Failed to find pragma \"" & name & "\" on node")
   case ast.kind:
   of nnk_pragma:
      let i = find_pragma(ast, name)
      if i == -1:
         err()
      else:
         result = ast[i]
   of nnk_proc_def:
      result = get_pragma(ast.pragmas, name, ast)
   of nnk_pragma_expr:
      result = get_pragma(ast.pragmas, name, ast)
   else:
      unexp_err(ast)

proc remove_pragma*(ast: NimNode, name: string, must_exist = false) =
   if must_exist and not ast.has_pragma(name):
      ast.err("Failed to remove pragma \"" & name & "\" on node")
   case ast.kind:
   of nnk_pragma:
      let i = find_pragma(ast, name)
      if i != -1:
         ast.delete(i)
   of nnk_proc_def:
      remove_pragma(ast.pragmas, name)
      if ast.pragmas.len == 0:
         ast.pragmas = empty
   of nnk_pragma_expr:
      remove_pragma(ast.pragmas, name)
   else:
      unexp_err(ast)

template add_ast*(stmts: NimNode, ast: untyped) =
   stmts.add quote do: ast
