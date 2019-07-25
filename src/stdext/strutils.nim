import
  ./macros,
  std/strutils as sysstrutils

export
  sysstrutils

proc noStyle*(s: string): string =
  result = toLowerAscii(s)
  result[0] = s[0]
