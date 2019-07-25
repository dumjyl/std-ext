
version = "0.1.0"
author = "Jasper Jenkins"
description = "stdlib extensions for nim for me"
license = "MIT"

srcDir = "src"
requires "nim >= 0.20.2"

task test, "run tests":
  const srcFiles = [
    1: "stdext/meta.nim"
  ]
  for srcFile in srcFiles:
    exec "nim cpp -r src/" & srcFile
