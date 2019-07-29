import
  ../stdext,
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

testFn:
  assert "_teST".noStyle == "test"
  assert "TesT_t_T__".noStyle == "Testtt"
