import
  system/io as sysio,
  std/os as sysos

export
  sysos except File

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
