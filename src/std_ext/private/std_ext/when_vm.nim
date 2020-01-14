import ../../macros

macro when_vm*(branches: varargs[untyped]): untyped =
   var (vm, other) = (
      case branches.len:
      of 1: (branches[0], gen_stmts())
      of 2: (branches[0], branches[1][0])
      else:
         error("incorrect branch count for `when_vm`")
         (nil, nil))
   result = nnk_when_stmt.init(
      nnk_elif_branch.init(id"nim_vm", vm.copy()),
      nnk_else.init(
         nnk_when_stmt.init(
            nnk_elif_branch.init(gen_call("defined", id"nim_script"), vm),
            nnk_else.init(other))))
