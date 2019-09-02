import
   ./option,
   std/os as sys_os,
   ./private/os/[os_proc]

export
   sys_os except get_env

export
   os_proc

proc cur_dir*: string =
   result = expand_tilde(get_current_dir())

proc get_env*(`var`: string): Opt[string] =
   if exists_env(`var`):
      result = Opt.init(sys_os.get_env(`var`))
   else:
      result = string.none()
