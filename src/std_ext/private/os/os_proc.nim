import
  ../../../std_ext,
  ../../str_utils,
  std/[osproc, streams]

export
  ProcessOption

proc exec*(command: string, args: openarray[string] = [],
           options = {po_stderr_to_stdout, po_use_path},
           working_dir = ""): tuple[output: string, code: int] =
  var p = start_process(command, working_dir = working_dir, args = args,
                        options = options)
  var outp = p.output_stream()
  var line = string.of_cap(120)
  while true:
    if outp.read_line(line):
      result.output.add(line)
      result.output.add("\n")
    else:
      result.code = p.peek_exit_code()
      if result.code != -1:
        break
  p.close()

proc exec_live*(command: string, args: openarray[string] = []): int =
  exec_cmd(command & " " & args.join(" "))
