import
   std/terminal,
   str_utils,
   macros

gen:
   result = gen_stmts()
   for color in fg_black..fg_white:
      let color_str = color.`$`.substr(2).to_lower_ascii()
      let color = gen_lit(color)
      let name = id(color_str)
      let bright_name = id("bright_" & color_str)
      result.add_ast:
         proc `name`*(str: string): string =
            result = ansi_foreground_color_code(`color`, false) &
                     str &
                     ansi_reset_code
         proc `bright_name`*(str: string): string =
            result = ansi_foreground_color_code(`color`, true) &
                     str &
                     ansi_reset_code
