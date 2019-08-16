import
  ../std_ext,
  ./str_utils,
  ./option,
  ./private/os/[os_proc, scoped_file],
  system/io as sys_io,
  std/os as sys_os

export
  sys_os except File, get_env

export
  os_proc,
  scoped_file

type
  File* = object
    impl: sysio.File

proc `=destroy`*(file: var File) =
  file.impl.close()

proc init*(_: typedesc[File], file_path: string, mode = fm_read): File =
  result = File(impl: file_path.open(mode))

proc len*(file: File): int64 =
  result = get_file_size(file.impl)

proc write(file: var File; s: string) =
  file.impl.write(s)

proc read_all_as(file: File, T: typedesc[char]): string =
  result = string.init(file.len)
  do_assert(result.len == file.impl.read_buffer(addr result[0], result.len))

proc read_all_as(file: File, T: typedesc): seq[T] =
  let flen = file.len
  if flen mod size_of(T) != 0:
    IOError.throw("file of size " & flen & " not interpretable as " $T & "s")
  result = seq[T].init(flen div size_of(T))
  do_assert(flen * size_of(T) == file.impl.read_buffer(addr result[0],
                                                       result.len))

proc read_bytes*(filename: string): seq[uint8] =
  let file = File.init(filename)
  result = seq[uint8].init(file.len)
  do_assert(result.len == file.impl.read_bytes(result, 0, result.len))

proc cur_dir*: string =
  result = expand_tilde(get_current_dir())

proc get_env*(`var`: string): Option[string] =
  if exists_env(`var`):
    result = Option.init(sys_os.get_env(`var`))
  else:
    result = Option[string].none()
