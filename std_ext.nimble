version = "0.8.0"
author = "Jasper Jenkins"
description = "stdlib extensions for nim for me"
license = "MIT"

src_dir = "src"
requires "nim >= 0.20.2"

import
   os,
   sequtils

proc collect_files_rec(dir: string): seq[string] =
   var dirs = @[dir]
   while dirs.len > 0:
      for entry in walk_dir(dirs.pop()):
         case entry.kind:
         of pcFile, pcLinkToFile:
            result.add(entry.path)
         of pcDir, pcLinkToDir:
            dirs.add(entry.path)

proc release_flag(name: string): string =
   if name.contains("hashes"):
      result = " -d:release "
   else:
      result = ""

const disabled = [""]

task test, "run tests":
   let src_files = (collect_files_rec("src") & collect_files_rec("tests"))
                    .filter_it(it.ends_with(".nim"))
   for src_file in src_files:
      if src_file.extract_filename notin disabled:
         try:
            exec "nim cpp -r -d:testing --threads:on " &
               release_flag(src_file) & src_file
         except:
            echo "failed processing: ", src_file
            raise

task docs, "build docs":
   var src_files: seq[string]
   for dir in ["src", "src/std_ext", "src/std_ext/c_ffi"]:
      src_files.add(collect_files_rec(dir).filter_it(it.ends_with(".nim")))
   for src_file in src_files:
      exec "nim doc --threads:on " & src_file
