import
   ./std_ext,
   ./std_ext/str_utils

anon:
   assert no_style("_teST") == "test"
   assert no_style("TesT_t_T__") == "Testtt"
