import
   ../../std_ext

const
   H = "<memory>"

type
   cpp_shared_ptr*[T] {.import_cpp: "std::shared_ptr<'0>", header: H.} = object
