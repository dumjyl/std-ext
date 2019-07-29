import
  ../stdext,
  std/terminal as systerminal

template withForegroundColor(color: ForegroundColor; stmts: untyped): untyped =
  stdout.setForegroundColor(color)
  stmts
  stdout.setForegroundColor(fgDefault)

template echoBad*(args: varargs[untyped]) =
  withForegroundColor(fgRed):
    echo("▲ ", args, " ▲")

template echoWarn*(args: varargs[untyped]) =
  withForegroundColor(fgYellow):
    echo("◆ ", args, " ◆")

template echoGood*(args: varargs[untyped]) =
  withForegroundColor(fgCyan):
    echo("● ", args, " ●")

template quitBad*(args: varargs[untyped]) =
  echoBad(args)
  quit(QuitFailure)

template quitWarn*(args: varargs[untyped]) =
  echoWarn(args)
  quit(QuitSuccess)

template quitGood*(args: varargs[untyped]) =
  echoGood(args)
  quit(QuitSuccess)
