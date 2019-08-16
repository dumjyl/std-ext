import
  ../../std_ext

const H = "<string>"

type
  cpp_string*{.import_cpp: "std::string", header: H.} = object

proc init*: cpp_string
  {.inits, import_cpp: "std::string()", constructor, header: H.}

proc init*(n: c_size, c: char): cpp_string
  {.inits, import_cpp: "std::string(##, #)", constructor, header: H.}

proc init*(c_str: c_string): cpp_string
  {.inits, import_cpp: "std::string(##)", constructor, header: H.}

proc init*(str: string): cpp_string {.inits.} =
  result = cpp_string.init(str.c_string)

proc c_str*(self: cpp_string): c_string
  {.import_cpp: "#.c_str()", header: H.}

proc size*(self: cpp_string): c_size
  {.import_cpp: "#.size()", header: H.}

proc push_back*(self: var cpp_string; c: char)
  {.import_cpp: "#.push_back(@)", header: H.}

proc `[]`*(self: cpp_string, i: int)
  {.import_cpp: "#[#]", header: H.}

proc `[]`*(self: var cpp_string, i: int): var char
  {.import_cpp: "#[#]", header: H.}

proc `[]=`*(self: var cpp_string, i: int, c: char)
  {.import_cpp: "#[#] = #", header: H.}

proc add*(self: var cpp_string, c: char) =
  self.push_back(c)

proc len*(self: cpp_string): int =
  result = int(self.size())

proc low*(self: cpp_string): int =
  result = 0

proc high*(self: cpp_string): int =
  result = self.len - 1

proc `$`*(s: cpp_string): string =
  result = $s.c_str()

test_proc:
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
