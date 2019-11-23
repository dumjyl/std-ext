import
   ../../../std_ext,
   ../../str_utils,
   std/[osproc, streams]

export
   osproc,
   streams

proc init*(
      command: string,
      args: openarray[string] = [],
      options: set[ProcessOption] = {po_stderr_to_stdout, po_use_path},
      working_dir: string = "",
      ): Process {.attach, inline.} =
   ## `Process` constructor.
   result = start_Process(command, working_dir, args, nil, options)

proc exec*(
      command: string,
      args: openarray[string] = [],
      options = {po_stderr_to_stdout, po_use_path},
      working_dir = ""
      ): tuple[output: string, code: int] =
   ## Return the output and code of a command.
   var p = Process.init(command, args, options, working_dir)
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
