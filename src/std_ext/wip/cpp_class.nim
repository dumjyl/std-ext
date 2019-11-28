import
   pkg/std_ext,
   pkg/std_ext/[macros,
                str_utils]
from pkg/std_ext/c_ffi import emit

# XXX: is this worth 500 loc?

type
   HeadInfo = object
      class: Node
      base: Node
      base_is_public: bool
      no_nim_inherit: bool
   FieldInfo = object
      name: Node
      typ: Node
      is_public: bool
   FuncKind = enum
      fk_method
      # fk_static
      fk_ctor
      # fk_dtor
   FuncInfo = object
      ast: Node
      kind: FuncKind
      friend_sym: Node
      init_list: Node
      is_virtual: bool
      is_public: bool
      is_imported: bool
   FormalInfo = object
      name: Node
      typ: Node
      val: Node
      len_of_name: Node
   AccessSpecifier = enum as_none, as_private, as_public

# TODO: generic functions
# TODO: docs
# TODO: tests
# TODO: multiple inheritance
# TODO: how initialization of nim types be handled
# TODO: gc traversals
# TODO: export syntax
# TODO: virtual
# TODO: abstract: use {.error.}
# TODO: export_cpp

proc init(
      Self: type[FieldInfo],
      ast: Node,
      access_specifier: AccessSpecifier
      ): FieldInfo =
   result = FieldInfo(name: ast[0],
                      typ: ast[1][0],
                      is_public: [as_none: false,
                                  as_private: false,
                                  as_public: true][access_specifier])

proc is_public(fn: Node): bool =
   fn.needs_kind(nnk_proc_def)
   result = fn[0].kind == nnk_postfix and `id==`(fn[0][0], "*")

proc name(fn: FuncInfo): string =
   result = fn.ast[fn_name_pos].str

proc init(
      Self: type[FuncInfo],
      ast: Node,
      access_specifier: AccessSpecifier
      ): FuncInfo =
   result = FuncInfo(ast: ast)
   result.friend_sym = nsk_proc.init(result.name)
   case access_specifier:
   of as_none:
      result.is_public = ast.is_public
   of as_private:
      if ast.is_public:
         ast.err("Conflicting privacy specification")
      else:
         result.is_public = false
   of as_public:
      result.is_public = true
   if result.ast.has_pragma("constructor"):
      result.kind = fk_ctor
      let init_list = result.ast.get_pragma("constructor")
      if init_list.kind == nnk_expr_colon_expr:
         result.init_list = init_list[1]
      result.ast.remove_pragma("constructor")
   else:
      result.kind = fk_method
   if result.ast.has_pragma("virtual"):
      result.is_virtual = true
      result.ast.remove_pragma("virtual")

proc init(
      Self: type[FormalInfo],
      name: Node,
      typ: Node,
      val = empty,
      len_of_name: Node = nil
      ): FormalInfo =
   result = FormalInfo(name: name, typ: typ, val: val, len_of_name: len_of_name)

proc is_type_ident(n: Node): bool =
   # TODO: macro/template calls can also generate types.
   #       range, ptr, distinct invalid too?
   #       for now just assume valid.
   result = true
   # case n.kind:
   # of nnk_ident, nnk_acc_quoted: result = n.is_simple_ident
   # of nnk_dot_expr, nnk_bracket_expr:
   #   result = n[0].is_simple_ident
   #   for i in 1 ..< n.len:
   #     result = result and n[i].is_type_ident
   # else: result = false

proc name_err(name_expr: Node) =
   name_expr.err_ex("Failed to parse class name")

proc head_lhs(result: var HeadInfo, lhs: Node) =
   case lhs.kind:
   of nnk_ident:
      result.class = lhs
   of nnk_pragma_expr:
      if lhs.len != 2 or lhs[0].kind != nnk_ident or lhs[1].kind != nnk_pragma:
         name_err(lhs)
      else:
         # TODO: better pragma validation.
         result.class = lhs[0]
         result.no_nim_inherit = lhs.has_pragma("no_nim_inherit")
   else:
      name_err(lhs)

proc init(Self: type[HeadInfo], name_expr: Node): HeadInfo =
   case name_expr.kind:
   of nnk_ident, nnk_pragma_expr:
      result.head_lhs(name_expr)
   of nnk_infix:
      if name_expr.len != 3 or `id!=`(name_expr[0], "of") or
         name_expr[1].kind notin {nnk_ident, nnk_pragma_expr}:
         name_err(name_expr)
      else:
         result.head_lhs(name_expr[1])
         if name_expr[2].kind == nnk_command and name_expr[2].len == 2 and
               `id==`(name_expr[2][0], "public") and
               name_expr[2][1].is_type_ident:
            result.base = name_expr[2][1]
            result.base_is_public = true
         elif name_expr[2].is_type_ident:
            result.base = name_expr[2]
            result.base_is_public = false
         else:
            name_err(name_expr)
   else:
      name_err(name_expr)

proc is_section(n: Node, sec_name: string): bool =
   result = n.kind == nnk_call and n.len == 2 and n[0].kind == nnk_ident and
            n[1].kind == nnk_stmt_list and `id==`(n[0], sec_name)

proc is_simple_ident(n: Node): bool =
   case n.kind:
   of nnk_ident: result = true
   of nnk_acc_quoted:
      for n in n:
         if n.kind != nnk_ident:
            return false
      result = true
   else: result = false

proc is_field(n: Node): bool =
   result = n.kind == nnk_call and n.len == 2 and n[0].is_simple_ident and
            n[1].kind == nnk_stmt_list and n[1].len == 1 and
            n[1][0].is_type_ident

proc collect(
      n: Node,
      access_specifier: AccessSpecifier,
      fields: var seq[FieldInfo],
      funcs: var seq[FuncInfo]) =
   if n.kind == nnk_proc_def:
      funcs.add(FuncInfo.init(n, access_specifier))
   elif n.is_field:
      fields.add(FieldInfo.init(n, access_specifier))
   else:
      n.err_ex("Unrecognized class stmt")

proc gen_class_type(
      head: HeadInfo,
      fields: seq[FieldInfo]): Node =
   var field_defs = seq[Node].init()
   for field in fields:
      let field_name = if field.is_public: make_public(field.name)
                     else: field.name
      field_defs.add(gen_def_typ(field_name, field.typ))
   var pragmas = nnk_pragma.init(id"import_cpp")
   if head.base == nil:
      pragmas.add(id"inheritable")
   # XXX: better handling for Foo : Base<Foo>
   var inherits = if head.no_nim_inherit: nil else: head.base
   result = gen_type_def(nnk_pragma_expr.init(head.class, pragmas),
                         gen_obj_ty(field_defs, inherits = inherits))

proc gen_type_of(typ: Node): Node =
   result = gen_call("type_of", typ)

template emits(vals: varargs[Node, gen_lit]): seq[Node] =
   @vals

proc gen_field_decl(field: FieldInfo): seq[Node] =
   result = emits(gen_type_of(field.typ), " ", field.name.str_val, ";\n")

proc get_return_typ(fn: FuncInfo): Node =
   if fn.ast.params[0].kind == nnk_empty:
      result = gen_lit"void"
   else:
      result = gen_type_of(fn.ast.params[0])

proc is_varargs(n: Node): bool =
   result = n.kind == nnk_bracket_expr and n.len == 2 and
            `id==`(n[0], "varargs")

proc get_formals(fn: FuncInfo, expand_args: bool): seq[FormalInfo] =
   for param in fn.ast.params[1 .. ^1]:
      for name in def_syms(param):
         result.add(FormalInfo.init(name, param[^2], param[^1]))
         if expand_args and param[^2].is_varargs:
            result.add(FormalInfo.init(id(name.str_val & "_len"),
                                       id"int", param[^1], name))

template add(self: seq[Node], vals: varargs[Node, gen_lit]) =
   system.add(self, vals)

template add(self: Node, vals: varargs[Node, gen_lit]) =
   macros.add(self, vals)

proc get_formals_decl(
      fn: FuncInfo,
      prepend: openarray[FormalInfo] = []
      ): seq[Node] =
   result.add(gen_lit"(")
   var first = true
   for i, f in prepend & fn.get_formals(true):
      if not first:
         result.add(", ")
      result.add(gen_type_of(f.typ))
      result.add(" " & f.name.str)
      first = false
   result.add(gen_lit(")"))

template add_decl_def =
   if with_def:
      result.add(" { ")
      if fn.ast.params[0].kind != nnk_empty:
         result.add("return ")
      result.add(fn.friend_sym)
      result.add("(*this")
      for i, formal in fn.get_formals(true):
         result.add(", " & formal.name.str)
      result.add("); }")
   else:
      result.add(";")

proc gen_method_decl(fn: FuncInfo, with_def: bool): seq[Node] =
   result = emits(get_return_typ(fn), " ", fn.name)
   result.add(get_formals_decl(fn))
   add_decl_def()

proc gen_ctor_decl(head: HeadInfo, fn: FuncInfo, with_def: bool): seq[Node] =
   # TODO: init list expressions, only constructors/assignments supported
   let name = gen_type_of(head.class)
   result = emits(name)
   result.add(get_formals_decl(fn))
   # TODO: validate these, don't use lazy repr hack
   if with_def and fn.init_list != nil:
      result.add(" : ")
      var first = true
      for init in fn.init_list:
         if not first:
            result.add(", ")
         result.add(repr(init))
         first = false
   add_decl_def()

proc gen_friend_decl(head: HeadInfo, fn: FuncInfo): seq[Node] =
   result = emits("friend ", get_return_typ(fn), " ", fn.friend_sym)
   let self = FormalInfo.init(id"self", nnk_var_ty.init(head.class))
   result.add(get_formals_decl(fn, [self]))
   result.add(";\n")

proc gen_class_declaration_head(head: HeadInfo): seq[Node] =
   result.add("class ", gen_type_of(head.class))
   if head.base != nil:
      result.add(" : ")
      if head.base_is_public:
         result.add("public ")
      result.add(gen_type_of(head.base))
   result.add(" {\n")

proc get_def_guard(head: HeadInfo): string =
   result = "NIM_CLASS_GURAD_" & head.class.str_val

proc define_def_guard(head: HeadInfo): string =
   result = "#define " & get_def_guard(head) & "\n"

proc gen_class_declaration(
      head: HeadInfo,
      fields: seq[FieldInfo],
      funcs: seq[FuncInfo],
      with_defs: bool,
      ): Node =
   var decl = gen_call(bind_sym"emit")
   if not with_defs:
      decl.add("/*TYPESECTION*/\n")
      decl.add("#ifndef ", get_def_guard(head) & "\n")
      decl.add(define_def_guard(head))
   decl.add(gen_class_declaration_head(head))
   var prev_is_public = false
   template accessor(info) =
      if prev_is_public != info.is_public:
         if info.is_public:
            decl.add("public:\n")
         else:
            decl.add("private:\n")
         prev_is_public = info.is_public
   for field in fields:
      accessor(field)
      decl.add(gen_field_decl(field))
   for fn in funcs:
      accessor(fn)
      if fn.is_virtual:
         decl.add("virtual ")
      case fn.kind:
      of fk_ctor:
         decl.add(gen_ctor_decl(head, fn, with_defs))
      else:
         decl.add(gen_method_decl(fn, with_defs))
      decl.add("\n")
      decl.add(gen_friend_decl(head, fn))
   decl.add("};\n")
   if not with_defs:
      decl.add("#endif")
   result = decl

proc gen_class_declaration_template(
      head: HeadInfo,
      fields: seq[FieldInfo],
      funcs: seq[FuncInfo]
      ): Node =
   # TODO: when to do this.
   # if head.base != nil:
   #  stmts.add(gen_call("declare", gen_call("typedesc", head.base)))
   result = gen_proc(
      id("declare", public = true),
      [gen_def_typ(id"Self", gen_gnrc(id"typedesc", head.class))],
      stmts = gen_class_declaration(head, fields, funcs, false),
      kind = nnk_template_def)

proc to_def(formal: FormalInfo, with_val = true): Node =
   if with_val:
      result = gen_def(formal.name, formal.typ, formal.val)
   else:
      result = gen_def_typ(formal.name, formal.typ)

proc add_pragma(fn: Node, name: string) =
   fn.add_pragma(id(name))

proc add_pragma(fn: Node, name: string, val: string) =
   fn.add_pragma(gen_colon(id(name), gen_lit(val)))

proc set_fn_params(
      params: Node,
      head: HeadInfo,
      fn: FuncInfo,
      is_swizzle: bool) =
   var formals = fn.get_formals(false)
   var formals_expanded = fn.get_formals(true)
   if fn.kind == fk_ctor:
      params[0] = head.class
   params.set_len(1)
   case fn.kind:
   of fk_ctor:
      params.add(gen_def_typ(id"Self", gen_gnrc(id"typedesc", head.class)))
   else:
      params.add(gen_def_typ(id"self", head.class))
   if is_swizzle:
      for formal in formals:
         params.add(formal.to_def(true))
   else:
      for formal in formals_expanded:
         params.add(formal.to_def(formals == formals_expanded))

proc gen_new_ctor(fn_ast: Node): Node =
   result = fn_ast.copy
   result.name = id"new"
   result.params[0] = nnk_ptr_ty.init(result.params[0])
   result.remove_pragma("constructor")
   result.get_pragma("import_cpp")[1] = gen_lit"(new '*0(@))"

proc gen_pattern_declarations(head: HeadInfo, fn: FuncInfo): Node =
   var pattern_fn = fn.ast.copy
   pattern_fn.body = empty
   pattern_fn.params.set_fn_params(head, fn, false)
   case fn.kind:
   of fk_ctor:
      pattern_fn.add_pragma("import_cpp", "'0(@)")
      pattern_fn.add_pragma("constructor")
   else:
      pattern_fn.add_pragma("import_cpp")
   if fn.get_formals(true) == fn.get_formals(false):
      pattern_fn[0] = make_public(pattern_fn[0])
      result = gen_stmts(pattern_fn)
      if fn.kind == fk_ctor:
         result.add(gen_new_ctor(pattern_fn))
   else:
      # TODO: swizzle new
      var swizzle_fn = fn.ast.copy
      swizzle_fn.params.set_fn_params(head, fn, true)
      let pattern_fn_name = nsk_proc.init(fn.name)
      pattern_fn[0] = pattern_fn_name
      var call = gen_call(pattern_fn_name)
      if fn.kind == fk_ctor:
         call.add(id"Self")
      else:
         call.add(id"self")
      for formal in fn.get_formals(true):
         if formal.len_of_name != nil:
            call.add(gen_call("len", formal.len_of_name))
         else:
            call.add(formal.name)
      swizzle_fn.body = gen_asgn(id"result", call)
      swizzle_fn[0] = make_public(swizzle_fn[0])
      result = gen_stmts(pattern_fn, swizzle_fn)

proc gen_friend_definition(head: HeadInfo, fn: FuncInfo): Node =
   result = fn.ast.copy
   if result.body == empty:
      result.body = gen_stmts()
   result[0] = fn.friend_sym
   result.params.insert(1, gen_def_typ(id"self", nnk_var_ty.init(head.class)))

macro class*(name, stmts: untyped): untyped =
   let head = HeadInfo.init(name)
   var fields = seq[FieldInfo].init()
   var funcs = seq[FuncInfo].init()
   for stmt in stmts:
      if stmt.is_section("public"):
         for stmt in stmt[1]:
            collect(stmt, as_public, fields, funcs)
      elif stmt.is_section("private"):
         for stmt in stmt[1]:
            collect(stmt, as_private, fields, funcs)
      elif stmt.kind == nnk_discard_stmt:
         discard
      else:
         collect(stmt, as_none, fields, funcs)
   result = gen_stmts()
   result.add(gen_class_type(head, fields))
   for fn in funcs:
      result.add(gen_pattern_declarations(head, fn))
      result.add(gen_friend_definition(head, fn))
   result.add(gen_call(bind_sym"emit", gen_lit"/*TYPESECTION*/ class ",
                       gen_type_of(head.class), gen_lit(";" & '\n'),
                       gen_lit(define_def_guard(head))))
   result.add(gen_class_declaration(head, fields, funcs, true))
   result.add(gen_class_declaration_template(head, fields, funcs))
