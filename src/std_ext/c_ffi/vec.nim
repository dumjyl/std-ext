import
  ../../std_ext

const H = "<vector>"

type
  cpp_vector*[T] {.import_cpp: "std::vector<'0>", header: H.} = object

proc init_impl[T](TInner: typedesc[T]): cpp_vector[T]
  {.inits, import_cpp: "std::vector<'2>()", constructor, header: H.}

proc init*[T]: cpp_vector[T] {.inits.} =
  result = cpp_vector[T].init_impl(T)

proc push_back*[T](vec: cpp_vector[T], val: T)
  {.import_cpp: "#.push_back(@)", header: H.}

proc reserve*[T](vec: cpp_vector[T], cap: c_size)
  {.import_cpp: "#.reserve(@)", header: H.}

proc init*[T](xs: seq[T]): cpp_vector[T] {.inits.} =
  result = cpp_vector[T].init()
  result.reserve(xs.len.c_size)
  for x in xs:
    result.push_back(x)
