import
   ../std_ext,
   macros,
   std/strutils as sys_str_utils

export
   sys_str_utils

proc no_style*(s: string): string =
   result = s.to_lower_ascii().multi_replace({"_": "", " ": ""})
   var i = 0
   while s[i] == '_' and i+1 < s.len:
      inc(i)
   if result.len > 0:
      result[0] = s[i]

proc surround*(strs: openarray[string], lhs, rhs: string, join = ", "): string =
   var len = lhs.len + join.len * max(strs.len - 1, 0) + rhs.len
   for i in span(strs):
      len += strs[i].len
   result = string.of_cap(len)
   result &= lhs
   var first = true
   for i in span(strs):
      if not first:
         result &= join
      result &= strs[i]
      first = false
   result &= rhs

proc surround*(str: string, lhs, rhs: string, join = ", "): string =
   result = [str].surround(lhs, rhs, join)

proc ln*[T](self: var string, val: T) =
   ## Add a `$val` followed by a newline.
   self &= $val & '\n'

proc ln*(self: var string) =
   ## Add a newline.
   self &= '\n'

proc lns*[T](self: var string, vals: openarray[T]) =
   for val in vals:
      self.ln(val)

proc quoted*(val: char|string): string =
   ## Get a quoted version of val.
   result.add_quoted(val)
