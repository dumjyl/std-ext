import
  std/os

type
  ScopedFile* = object
    file_path*: string

proc `=destroy`*(scopedFile: var ScopedFile) =
  remove_file(scopedFile.file_path)

proc init*(_: typedesc[ScopedFile], file_path: string,
           contents: string): ScopedFile =
  write_file(file_path, contents)
  result = ScopedFile(file_path: file_path)

proc get_tmp_filename(ext: string): string =
  once: create_dir(get_temp_dir()/"scopedtmp")
  var count {.global.} = 0
  result = get_temp_dir()/"scopedtmp"/"tmp" & $count & ext
  inc(count)

proc init_temp*(_: typedesc[ScopedFile], contents: string,
                ext = ""): ScopedFile =
  result = ScopedFile.init(get_tmp_filename(ext), contents)

template get_temp_file*(contents: string, ext = ""): string =
  var scoped_file = ScopedFile.init_temp(contents, ext)
  scoped_file.file_path
