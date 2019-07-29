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
  File* = object
    impl: sysio.File
  ScopedFile* = object
    filename*: string

proc `=destroy`*(file: var File) =
  file.impl.close()

proc initFile*(filename: string; mode = fmRead): File =
  result = File(impl: filename.open(mode))

proc len*(file: File): int64 =
  result = getFileSize(file.impl)

proc write(file: var File; s: string) =
  file.impl.write(s)

proc readAllAs(file: File, T: typedesc[char]): string =
  result = newString(file.len)
  doAssert(result.len == file.impl.readBuffer(addr result[0], result.len))

proc readAllAs(file: File, T: typedesc): seq[T] =
  let flen = file.len
  if flen mod sizeof(T) != 0:
    raise newException(IOError, "file of size " & flen &
                       " not interpretable as " $T & "s")
  result = newSeq[T](flen div sizeof(T))
  doAssert(flen * sizeof(T) == file.impl.readBuffer(addr result[0], result.len))

proc readBytes*(filename: string): seq[uint8] =
  let file = initFile(filename)
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

proc `=destroy`*(scopedFile: var ScopedFile) =
  removeFile(scopedFile.filename)

proc initScopedFile*(filename, contents: string): ScopedFile =
  writeFile(filename, contents)
  result = ScopedFile(filename: filename)

proc getTmpFilename(ext: string): string =
  once: createDir(getTempDir()/"scopedtmp")
  var count {.global.} = 0
  result = getTempDir()/"scopedtmp"/"tmp" & $count & ext
  inc(count)

proc initScopedTemp*(contents: string, ext = ""): ScopedFile =
  result = initScopedFile(getTmpFilename(ext), contents)

template getTempFile*(contents: string; ext = ""): string =
  var scopedFile = initScopedTemp(contents, ext)
  scopedFile.filename

test:
  proc testsScopedFileReturnsPath(): string =
    let tmpFile = initScopedTemp("scopetest")
    result = tmpFile.filename[0..^1] # bug

testFn:
  let (output, code) = exec("echo", ["test"])
  doAssert(code == 0 and output == "test\n")
  doAssert(not fileExists(testsScopedFileReturnsPath()))
