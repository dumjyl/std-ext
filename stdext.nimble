
version = "0.3.2"
author = "Jasper Jenkins"
description = "stdlib extensions for nim for me"
license = "MIT"

srcDir = "src"
requires "nim >= 0.20.2"

task test, "run tests":
  const srcFiles = [
    1: "stdext/meta.nim",
    2: "stdext/strutils.nim",
    3: "stdext/os.nim",
    4: "stdext.nim",
    5: "stdext/cffi/str.nim",
    6: "stdext/random.nim",
    7: "stdext/anon.nim",
  ]
  for srcFile in srcFiles:
    exec "nim cpp -r src/" & srcFile
