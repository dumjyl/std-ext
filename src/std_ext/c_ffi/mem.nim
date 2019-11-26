import
   ../../std_ext,
   ../c_ffi

const
   H = "<memory>"

type
   cpp_shared_ptr*[T] {.import_cpp: "std::shared_ptr<'0>", header: H.} = object
   cpp_unique_ptr*[T] {.import_cpp: "std::unique_ptr<'0>", header: H.} = object

proc init*[T](Self: type[cpp_unique_ptr[T]], val: ptr T): cpp_unique_ptr[T]
  {.import_cpp: "'0(@)", constructor.}
