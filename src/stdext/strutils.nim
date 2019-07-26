import
  ./macros,
  std/strutils as sysstrutils

export
  sysstrutils

proc noStyle*(s: string): string =
  result = s.toLowerAscii().multiReplace({"_": "", " ": ""})
  var i = 0
  while s[i] == '_' and i+1 < s.len: inc(i)
  if result.len > 0:
    result[0] = s[i]

when isMainModule:
  doAssert("_teST".noStyle == "test")
  doAssert("TesT_t_T__".noStyle == "Testtt")
