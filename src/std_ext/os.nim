import
   ./options,
   std/os as sys_os,
   ./private/os/os_proc

export
   sys_os except get_env, find_exe

export
   os_proc

proc cur_dir*: string =
   ## Return the current working directory.
   result = expand_tilde(get_current_dir())

proc get_env*(`var`: string): Opt[string] =
   ## Return an environment variable.
   if exists_env(`var`):
      result = some(sys_os.get_env(`var`))
   else:
      result = string.none()

proc find_exe*(exe: string): Opt[string] =
   ## Return an executable in the path.
   var exe_path = sys_os.find_exe(exe)
   if exe.len > 0:
      result = some(exe_path)
   else:
      result = string.none()

proc is_dir*(path: string): bool {.inline.} =
   ## Return if `path` is a directory.
   result = dir_exists(path)

proc is_file*(path: string): bool {.inline.} =
   ## Return if `path` is a file.
   result = file_exists(path)

proc is_symlink*(path: string): bool {.inline.} =
   ## Return if `path` is a symlink of some kind.
   when defined(unix):
      result = symlink_exists(path)
   else:
      result = false

proc is_dir_symlink*(path: string): bool {.inline.} =
   ## Return if `path` is symlink to a directory.
   result = is_dir(path) and is_symlink(path)

proc is_file_symlink*(path: string): bool {.inline.} =
   ## Return if `path` is symlink to a file.
   result = is_file(path) and is_symlink(path)
