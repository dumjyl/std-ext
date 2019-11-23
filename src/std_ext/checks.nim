include system/[fatal, indexerrors]
import
   ../std_ext

proc check_bounds*(i: isize, len: isize) {.inline.} =
   ## Idiomatic nim bounds checking.
   when compile_option("bound_checks"):
      if i < 0 or i >= len:
         sys_fatal(IndexError, format_error_index_bound(i, len-1))
