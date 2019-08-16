import
  ../std_ext,
  ./macros,
  std/strutils as sysstrutils

export
  sysstrutils

proc no_style*(s: string): string =
  result = s.to_lower_ascii().multi_replace({"_": "", " ": ""})
  var i = 0
  while s[i] == '_' and i+1 < s.len:
    inc(i)
  if result.len > 0:
    result[0] = s[i]
