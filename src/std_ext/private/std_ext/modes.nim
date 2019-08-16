template main*(stmts: untyped) =
  when is_main_module:
    stmts

template main_proc*(stmts: untyped) =
  main:
    proc impl_main_proc {.gen_sym.} =
      stmts
    impl_main_proc()

template test*(stmts: untyped) =
  when is_main_module and defined(testing):
    stmts

template test_proc*(stmts: untyped) =
  test:
    proc impl_test_proc {.gen_sym.} =
      stmts
    impl_test_proc()

template debug*(body: untyped): untyped =
  when not defined(release):
    body
