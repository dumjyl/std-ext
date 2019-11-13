import
   ../std_ext,
   ./c_ffi/str,
   system/io as sys_io

type
   FileEx* = object
      impl: File

proc `=`*(dst_f: var FileEx, src_f: FileEx) {.error.}

proc `=destroy`*(f: var FileEx) =
   if f.impl != nil:
      f.impl.close()
   f.impl = nil

proc `=sink`*(dst_f: var FileEx, src_f: FileEx) =
   `=destroy`(dst_f)
   dst_f.impl = src_f.impl

proc init*(
      file_path: string,
      mode = fm_read,
      buf_size: int = -1,
      ): FileEx {.attach.} =
   result = FileEx(impl: file_path.open(mode, buf_size))

proc sys*(f: FileEx): File =
   result = f.impl

proc len*(f: FileEx): i64 =
   result = get_file_size(f.impl)

proc pos*(f: FileEx): i64 =
   result = f.impl.get_file_pos()

proc `pos=`*(f: FileEx, pos: i64) =
   f.impl.set_file_pos(pos, fsp_set)

proc write*[T](f: FileEx, data: T) =
   let n_bytes_written = f.impl.write_buffer(unsafe_addr data, size_of(T))
   if unlikely(n_bytes_written != size_of(T)):
      IOError.throw("failed to write " & $T & " of " & $size_of(T) & " bytes" &
                    ", " & $n_bytes_written & " bytes written")

proc read*[T](f: FileEx, _: typedesc[T]): T =
   let n_bytes_read = f.impl.read_buffer(addr result, size_of(T))
   if unlikely(n_bytes_read != size_of(T)):
      IOError.throw("reading as " & $T & " failed. read " & $n_bytes_read &
                    " bytes, expected " & $size_of(T))

proc read*[T](f: FileEx, PT: typedesc[T], n: isize): T =
   let n_bytes_read = f.impl.read_buffer(addr result, size_of(T) * n)
   if unlikely(n_bytes_read != size_of(T) * n):
      IOError.throw("reading as " & $n & " " & $T & " failed. read " &
                    $n_bytes_read & " bytes, expected " & $size_of(T) * n)

proc read*[T](f: FileEx, data: ptr T, n: isize) =
   let n_bytes_read = f.impl.read_buffer(data, n * size_of(T))
   if unlikely(n_bytes_read != n * size_of(T)):
      IOError.throw("reading " & $n & " " & $T & " failed. read " &
                    $n_bytes_read & " bytes")

proc read*[T](f: FileEx, data: ptr UncheckedArray[T], n: isize) =
   f.read(data.bit_cast(ptr T), n)

proc read*(f: FileEx, data: pointer, n_bytes: isize) =
   let n_bytes_read = f.impl.read_buffer(data, n_bytes)
   if unlikely(n_bytes_read != n_bytes):
      IOError.throw("reading " & $n_bytes & " bytes failed. read " &
                    $n_bytes_read & " bytes")

# --- total read ---

proc read_file*[T: string](file_path: string, PT: typedesc[T]): T =
   var f = FileEx.init(file_path)
   result = string.init(f.len)
   f.read(result.mem, result.len)

proc read_file*[T](file_path: string, PT: typedesc[seq[T]]): seq[T] =
   var f = FileEx.init(file_path)
   if f.len mod size_of(T) != 0 and f.len > 0:
      IOError.throw("file len not divisible by size_of(T)")
   result = seq[T].init(f.len div size_of(T))
   f.read(result.mem, result.len)

proc read_file*[T: cpp_string](file_path: string, PT: typedesc[T]): T =
  var f = FileEx.init(file_path)
  result = cpp_string.init(f.len.isize, '\0')
  f.read(result.mem, result.len)
