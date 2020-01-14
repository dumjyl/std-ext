import
   pkg/std_ext,
   pkg/std_ext/macros,
   std/parseopt

export parseopt, fatal, loop

proc render_param*(opts: var OptParser): string =
   case opts.kind:
   of cmd_argument:
      result = opts.key
   of cmd_short_option:
      result = '-' & opts.key
   of cmd_long_option:
      result = "--" & opts.key
   of cmd_end: discard
   if opts.val.len > 0:
      result &= ':' & opts.val

template fatal_arg* =
   fatal("unexpected command line parameter: \'", render_param(opts), '\'')

macro process_opts*(branches: varargs[untyped]) =
   let opts_id = id"opts"
   let case_stmt = nnk_case_stmt.init(gen_dot(opts_id, id"kind"))
   for branch in branches:
      case_stmt.add(branch)
   case_stmt.add(nnk_of_branch.init(id"cmd_end", nnk_break_stmt.init(empty)))
   result = quote do:
      var `opts_id` = init_OptParser()
      template key: string {.inject, used.} = string(`opts_id`.key)
      template val: string {.inject, used.} = string(`opts_id`.val)
      template kind: CmdLineKind {.inject, used.} = `opts_id`.kind
      loop:
         `opts_id`.next()
         `case_stmt`
