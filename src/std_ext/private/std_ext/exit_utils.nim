import
   std_ext/colors,
   when_vm

type
   ExitRequest* = object of CatchableError
      exit_code*: int
      write_trace*: bool

proc init*(
      Self: type[ExitRequest],
      msg: string,
      exit_code: int,
      write_trace: bool
      ): ref ExitRequest =
   result = (ref ExitRequest)(msg: msg, exit_code: exit_code,
                              write_trace: write_trace)

template exit*(msg: string, exit_code: int, write_trace = false) =
   raise ExitRequest.init(msg, exit_code, write_trace)

template exit*(exit_code: int, write_trace = false) =
   raise ExitRequest.init("", exit_code, write_trace)

proc render_entry(entry: StackTraceEntry): string =
   result = $entry.filename
   result.add('(')
   result.add($entry.line)
   result.add(')')
   result.add(' ')
   result.add($entry.procname)

proc write_trace(exit_request: ref ExitRequest) =
   # XXX: js support
   let entries = get_stack_trace_entries(exit_request)
   if exit_request.write_trace and entries.len > 0:
      var output = ""
      when_vm:
         output.add(bright_yellow("Traceback:"))
      else:
         output.add(stderr.bright_yellow("Traceback:"))
      if entries.len == 1:
         output.add(' ')
         output.add(render_entry(entries[0]))
      else:
         output.add('\n')
         for i, entry in entries:
            output.add(render_entry(entry))
            if i != entries.high:
               output.add('\n')
      when_vm:
         echo output
      else:
         stderr.write(output)
         stderr.write('\n')

template exit_handler*(stmts: untyped) =
   try:
      stmts
   except ExitRequest as exit_request:
      write_trace(exit_request)
      quit(exit_request.msg, exit_request.exit_code)

template exit_handler*(on_exit: untyped, stmts: untyped) =
   when_vm:
      discard
   else:
      set_control_c_hook(proc {.no_conv.} =
         stderr.write(stderr.bright_yellow("Signal Interrupt:"), " ctrl-c")
         on_exit
         quit(1))
   try:
      stmts
   except ExitRequest as exit_request:
      on_exit
      write_trace(exit_request)
      quit(exit_request.msg, exit_request.exit_code)

template main*(stmts: untyped) =
   when is_main_module:
      proc main_fn: int {.gen_sym.} =
         exit_handler(stmts)
      {.line.}: quit(main_fn())

template main*(on_exit: untyped, stmts: untyped) =
   when is_main_module:
      proc main_fn: int {.gen_sym.} =
         exit_handler(on_exit, stmts)
         on_exit
      {.line.}: quit(main_fn())

template fatal*(msgs: varargs[string, `$`]) =
   var message: string
   when_vm: message = bright_red("Fatal:")
   else: message = stderr.bright_red("Fatal:")
   message.add(' ')
   for msg in msgs:
      message.add(msg)
   {.line.}: exit(message, 1, true)
