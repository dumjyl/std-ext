const H = "<string>"

type
  String*{.importcpp: "std::string", header: H.} = object

proc init*(self: typedesc[String]): String
  {.importcpp: "std::string()", constructor, header: H.}

proc cStr*(self: String): cstring
  {.importcpp: "#.c_str()", header: H.}

proc size*(self: String): csize
  {.importcpp: "#.size()", header: H.}

proc pushBack*(self: var String; c: char)
  {.importcpp: "#.push_back(@)", header: H.}

proc `[]`*(self: String; i: int)
  {.importcpp: "#[#]", header: H.}

proc `[]`*(self: var String; i: int): var char
  {.importcpp: "#[#]", header: H.}

proc `[]=`*(self: var String; i: int; c: char)
  {.importcpp: "#[#] = #", header: H.}

proc add*(self: var String; c: char) =
  self.pushBack(c)

proc len*(self: String): int =
  result = int(self.size())

proc low*(self: String): int =
  result = 0

proc high*(self: String): int =
  result = self.len - 1

proc `$`*(s: String): string =
  result = $s.cStr()

when isMainModule:
  var x = String.init()
  x.add('a')
  x.add('b')
  x.add('c')
  doAssert($x == "abc")
  x[2] = 'd'
  doAssert($x == "abd")
  var y = x[1].addr
  y[] = 'c'
  doAssert($x == "acd")
  doAssert(x.len == 3)