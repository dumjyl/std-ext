
version = "0.3.4"
author = "Jasper Jenkins"
description = "stdlib extensions for nim for me"
license = "MIT"

srcDir = "src"
requires "nim >= 0.20.2"

task test, "run tests":
  const srcFiles = [
    1: "stdext.nim",
    2: "stdext/anon.nim",
    3: "stdext/cffi.nim",
    4: "stdext/macros.nim",
    5: "stdext/mem.nim",
    6: "stdext/meta.nim",
    7: "stdext/os.nim",
    8: "stdext/random.nim",
    9: "stdext/strutils.nim",
    10: "stdext/types.nim",
    11: "stdext/typetraits.nim",
    12: "stdext/cffi/str.nim",
  ]
  for srcFile in srcFiles:
    exec "nim cpp -r src/" & srcFile
