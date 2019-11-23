import
   pkg/std_ext/macros,
   pkg/std_ext/dev_utils

static:
   block:
      let x = quote do: echo 1, 2, 3
      assert_eq($x, """Node:
  Literal:
    echo 1, 2, 3
  Tree:
    Command
      Sym "echo"
      IntLit 1
      IntLit 2
      IntLit 3""")

   block:
      let fn_ast = quote do:
         proc foo {.inline, import_cpp: "foo".}
      assert(fn_ast.has_pragma("i_n_l_i_n_e"))
      assert(fn_ast.get_pragma("iNLINE") == id"inline")
      assert(fn_ast.get_pragma("import_cpp") == gen_colon(id"import_cpp",
                                                          gen_lit"foo"))
      fn_ast.remove_pragma("inline")
      fn_ast.remove_pragma("importCpp")
      assert(not fn_ast.has_pragma("inline"))
      assert(not fn_ast.has_pragma("import_cpp"))
