import
   ../../std_ext

const
   H = "<vector>"

type
   cpp_vector*[T] {.import_cpp: "std::vector<'0>", header: H.} = object

proc init*[T]: cpp_vector[T] {.attach
   import_cpp: "std::vector<'*0>()", constructor, header: H.}

proc init*[T](n: isize): cpp_vector[T] {.attach
   import_cpp: "std::vector<'*0>(@)", constructor, header: H.}

proc push_back*[T](self: var cpp_vector[T], val: T)
   {.import_cpp: "#.push_back(@)", header: H.}

proc reserve*[T](self: var cpp_vector[T], cap: c_usize)
   {.import_cpp: "#.reserve(@)", header: H.}

proc size*[T](self: cpp_vector[T]): c_usize
   {.import_cpp: "#.size()", header: H.}

proc `[]`*[T](self: cpp_vector[T], i: isize): T
   {.import_cpp: "#[#]", header: H.}

proc `[]`*[T](self: var cpp_vector[T], i: isize): var T
   {.import_cpp: "#[#]", header: H.}

proc `[]=`*[T](self: var cpp_vector[T], i: isize, val: T)
   {.import_cpp: "#[#] = #", header: H.}

proc len*[T](self: cpp_vector[T]): isize {.inline.} =
   result = self.size

proc low*[T](self: cpp_vector[T]): isize {.inline.} =
   result = 0

proc high*[T](self: cpp_vector[T]): isize {.inline.} =
   result = self.len - 1

template span*[T](self: cpp_vector[T]): untyped =
   0 ..< self.len - 1

proc add*[T](self: var cpp_vector[T], val: T) {.inline.} =
   self.push_back(val)

proc init*[T](xs: openarray[T]): cpp_vector[T] {.attach.} =
   result = cpp_vector[T].init()
   result.reserve(xs.len.c_size)
   for x in xs:
      result.push_back(x)
