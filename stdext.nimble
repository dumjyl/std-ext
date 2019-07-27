
version = "0.3.0"
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
  ]
  for srcFile in srcFiles:
    exec "nim cpp -r src/" & srcFile
