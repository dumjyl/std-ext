import
   ./std_ext,
   ./std_ext/str_utils

run:
   assert no_style("_teST") == "test"
   assert no_style("TesT_t_T__") == "Testtt"
