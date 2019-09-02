import
   ../std_ext,
   ./str_utils,
   ./macros

{.experimental: "dot_operators".}

type
   Anonymous = object

const
   _* = Anonymous()
   fieldLookup = CacheTable"stdext/anon.fieldLookup"

macro `enum`*(fields: varargs[untyped]): untyped =
   var name = "Enum"
   var public = false
   if fields[0].kind == nnk_prefix and `id==`(fields[0][0], "*"):
      fields[0] = fields[0][1]
      public = true
   for f in fields:
      f.needs_kind(nnk_ident)
      name &= f.str
   result = nnk_stmt_list.tree(
      gen_type_def(id(name), nnk_enum_ty.tree(empty & sons(fields))),
      id(name))
   for f in fields:
      if public:
         fieldLookup[no_style(f.str)] = result

proc find_enum_type(field_str: string): Node =
   for field, enum_type in field_lookup:
      if no_style(field_str) == field:
         return enum_type
   error("anonymous field " & field_str & " not found")

macro `.`*(_: Anonymous; field: untyped): untyped =
   result = nnk_dot_expr.tree(find_enum_type(field.str), field)
