import
  ../stdext,
  ./strutils,
  system/io as sysio,
  std/os as sysos,
  std/osproc,
  std/streams

export
  sysos except File,
  ProcessOption

type
  File = object
    impl: sysio.File

proc `=destroy`*(file: var File) =
  close(file.impl)

proc initFile*(filepath: string; mode = fmRead): File =
  result = File(impl: filepath.open(mode))

proc len*(file: File): int64 =
  result = getFileSize(file.impl)

proc readBytes*(filepath: string): seq[uint8] =
  let file = initFile(filepath)
  result = newSeq[uint8](file.len)
  doAssert(result.len == file.impl.readBytes(result, 0, result.len))

proc curDir*: string =
  expandTilde(getCurrentDir())

proc exec*(command: string; args: openarray[string] = [];
           options = {poStdErrToStdOut, poUsePath};
           workingDir = ""): tuple[output: string; code: int] =
  var p = startProcess(command, workingDir = workingDir, args = args,
                       options = options)
  var outp = outputStream(p)
  var line = newStringOfCap(120)
  while true:
    if outp.readLine(line):
      result.output.add(line)
      result.output.add("\n")
    else:
      result.code = peekExitCode(p)
      if result.code != -1: break
  close(p)

proc execLive*(command: string, args: openarray[string] = []): int =
  execCmd(command & " " & args.join(" "))

main:
  let (output, code) = exec("echo", ["test"])
  doAssert(code == 0 and output == "test\n")
