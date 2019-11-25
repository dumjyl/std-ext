import
   ../../std_ext

const
   H = "<string>"

type
   cpp_string*{.import_cpp: "std::string", header: H.} = object

proc init*(Self: type[cpp_string]): cpp_string
  {.import_cpp: "std::string()", constructor, header: H.}

proc init*(Self: type[cpp_string], n: isize, c: char): cpp_string
  {.import_cpp: "std::string(@)", constructor, header: H.}

proc init*(Self: type[cpp_string],  c_str: c_string): cpp_string
  {.import_cpp: "std::string(@)", constructor, header: H.}

proc c_str*(self: cpp_string): c_string
   {.import_cpp: "#.c_str()", header: H.}

proc size*(self: cpp_string): c_usize
   {.import_cpp: "#.size()", header: H.}

proc push_back*(self: var cpp_string; c: char)
   {.import_cpp: "#.push_back(@)", header: H.}

proc `[]`*(self: cpp_string, i: isize): char
   {.import_cpp: "#[#]", header: H.}

proc `[]`*(self: var cpp_string, i: isize): var char
   {.import_cpp: "#[#]", header: H.}

proc `[]=`*(self: var cpp_string, i: isize, c: char)
   {.import_cpp: "#[#] = #", header: H.}

proc add*(self: var cpp_string, c: char) {.inline.} =
   self.push_back(c)

proc len*(self: cpp_string): isize {.inline.} =
   result = isize(self.size())

proc low*(self: cpp_string): isize {.inline.} =
   result = 0

proc high*(self: cpp_string): isize {.inline.} =
   result = self.len - 1

template span*(self: cpp_string): isize =
   0 .. self.len - 1

iterator items*(self: cpp_string): char {.inline.} =
   for i in span(self):
      yield self[i]

proc init*(Self: type[cpp_string], str: string): cpp_string {.inline.} =
   result = cpp_string.init()
   for c in str:
      result.add(c)

proc `$`*(str: cpp_string): string {.inline.} =
   result = string.init()
   for c in str:
      result.add(c)

proc mem*(self: var cpp_string): ptr char =
  result = self[0].addr

run(test):
   var x = cpp_string.init()
   x.add('a')
   x.add('b')
   x.add('c')
   assert($x == "abc")
   x[2] = 'd'
   assert($x == "abd")
   var y = x[1].addr
   y[] = 'c'
   assert($x == "acd")
   assert(x.len == 3)
   assert($cpp_string.init(3, 'q') == "qqq")
