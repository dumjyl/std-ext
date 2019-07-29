
version = "0.3.6"
author = "Jasper Jenkins"
description = "stdlib extensions for nim for me"
license = "MIT"

srcDir = "src"
requires "nim >= 0.20.2"

task test, "run tests":
  const srcFiles = [
    01: "stdext.nim",
    02: "stdext/anon.nim",
    03: "stdext/cffi.nim",
    04: "stdext/macros.nim",
    05: "stdext/mem.nim",
    06: "stdext/meta.nim",
    07: "stdext/os.nim",
    08: "stdext/random.nim",
    09: "stdext/strutils.nim",
    10: "stdext/types.nim",
    11: "stdext/typetraits.nim",
    12: "stdext/cffi/str.nim",
  ]
  for srcFile in srcFiles:
    exec "nim cpp -r src/" & srcFile
