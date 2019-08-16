import
  ./std_ext,
  ./std_ext/os

proc tests_scoped_file_returns_path(): string =
  let tmp_file = ScopedFile.init_temp("scopetest")
  result = tmp_file.file_path[0..^1]

main_proc:
  let (output, code) = exec("echo", ["test"])
  assert code == 0 and output == "test\n"
  assert not file_exists(tests_scoped_file_returns_path())
