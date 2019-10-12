import
   ./macros

type
   CppStd* = enum
      cpp_std03
      cpp_std_gnu03
      cpp_std11
      cpp_std_gnu11
      cpp_std14
      cpp_std_gnu14
      cpp_std17
      cpp_std_gnu17
      cpp_std20
      cpp_std_gnu20

template include_path*(path: static string) =
   {.pass_c: "-I" & path.}

template link_path*(path: static string) =
   {.pass_l: "-L" & path.}

template link*(lib: static string) =
   {.pass_l: "-l" & lib.}

macro link*(libs: static openarray[string]) =
   result = nnk_stmt_list.init()
   for lib in libs:
      result.add(gen_call("link", gen_lit(lib)))

template set_cpp_std*(std: static CppStd = cpp_std11) =
   when not defined(cpp):
      {.error: "module only supports c++ backend".}
   {.pass_c: "-std=" & [cpp_std03: "c++03", cpp_std_gnu03: "gnu++03",
                        cpp_std11: "c++11", cpp_std_gnu11: "gnu++11",
                        cpp_std14: "c++14", cpp_std_gnu14: "gnu++14",
                        cpp_std17: "c++17", cpp_std_gnu17: "gnu++17",
                        cpp_std20: "c++2a", cpp_std_gnu20: "gnu++2a"][std].}

template use_lib_cpp* =
   {.pass_c: "-stdlib=libc++".}
   {.pass_l: "-lc++".}
   {.pass_l: "-lc++abi".}

template local_include*(file: static string) =
   {.emit: "/*INCLUDESECTION*/ #include \"" & file & "\"".}

template sys_include*(file: static string) =
   {.emit: "/*INCLUDESECTION*/ #include <" & file & ">".}

template local_include_here*(file: static string) =
   {.emit: "#include \"" & file & "\"".}

template sys_include_here*(file: static string) =
   {.emit: "#include <" & file & ">".}
