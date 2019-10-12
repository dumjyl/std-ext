import
   ../std_ext,
   std/terminal as sys_terminal

export
   sys_terminal

template with_foreground_color(
      color: ForegroundColor,
      stmts: untyped
      ): untyped =
   stdout.set_foreground_color(color)
   stmts
   stdout.set_foreground_color(fg_default)

template echo_bad*(args: varargs[untyped]) =
   styled_echo(fg_red, "▲ ", args, " ▲")

template echo_warn*(args: varargs[untyped]) =
   styled_echo(fg_yellow, "◆ ", args, " ◆")

template echo_good*(args: varargs[untyped]) =
   styled_echo(fg_cyan, "● ", args, " ●")

template quit_bad*(args: varargs[untyped]) =
   echo_bad(args)
   quit(QuitFailure)

template quit_warn*(args: varargs[untyped]) =
   echo_warn(args)
   quit(QuitSuccess)

template quit_good*(args: varargs[untyped]) =
   echo_good(args)
   quit(QuitSuccess)
