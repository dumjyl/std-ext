import
   macros,
   std_ext/private/std_ext/when_vm,
   std/os

# Respects https://bixense.com/clicolors/ and https://no-color.org/

proc is_a_tty(f: File): bool =
   when defined(posix):
      proc is_a_tty(fildes: FileHandle): c_int
        {.import_c: "isatty", header: "<unistd.h>".}
   else:
      proc is_a_tty(fildes: FileHandle): c_int
        {.import_c: "_isatty", header: "<io.h>".}
   result = is_a_tty(get_file_handle(f)) != 0'i32

proc is_clicolor_env: bool =
   result = get_env("CLICOLOR", "1") != "0"

proc is_clicolor_force_env: bool =
   result = get_env("CLICOLOR_FORCE", "0") != "0"

proc is_clicolor: bool =
   template no_stdout =
      result = is_clicolor_env() or is_clicolor_force_env()
   when nim_vm:
      no_stdout
   else:
      when defined(nim_script) or defined(js):
         no_stdout
      else:
         result = (is_clicolor_env() and is_a_tty(stdout)) or
                   is_clicolor_force_env()

proc is_clicolor(f: File): bool =
   result = (is_clicolor_env() and is_a_tty(f)) or is_clicolor_force_env()

proc is_no_color: bool =
   result = exists_env("NO_COLOR")

proc is_color_enabled(f: File): bool =
   result = not is_no_color() and is_clicolor(f)

proc is_color_enabled: bool =
   result = not is_no_color() and is_clicolor()

template cmd(code: int): string = "\e[" & $code & 'm'

template apply_code(
      str: string,
      code: int,
      enabled_expr: bool = is_color_enabled()) =
    if enabled_expr:
       result = cmd(code) & str & cmd(0)
    else:
       result = str

gen:
   result = gen_stmts()
   for code, color in [30: "black", "red", "green", "yellow", "blue",
                       35: "magenta", "cyan", "white"]:
      let name = id(color)
      let bg_name = id("bg_" & color)
      let bright_name = id("bright_" & color)
      let bg_bright_name = id("bg_bright_" & color)
      let code = gen_lit(code)
      result.add_ast:
         proc `name`*(str: string): string =
            str.apply_code(`code`)
         proc `bg_name`*(str: string): string =
            str.apply_code(`code` + 10)
         proc `bright_name`*(str: string): string =
            str.apply_code(`code` + 60)
         proc `bg_bright_name`*(str: string): string =
            str.apply_code(`code` + 10 + 60)
         proc `name`*(f: File, str: string): string =
            str.apply_code(`code`, is_color_enabled(f))
         proc `bg_name`*(f: File, str: string): string =
            str.apply_code(`code` + 10, is_color_enabled(f))
         proc `bright_name`*(f: File, str: string): string =
            str.apply_code(`code` + 60, is_color_enabled(f))
         proc `bg_bright_name`*(f: File, str: string): string =
            str.apply_code(`code` + 10 + 60, is_color_enabled(f))
