import
   ../../macros

proc insert_type_param(fn: Node, T: Node) =
   fn.params.insert(1, gen_def_typ(id"Self", gen_typ(typedesc, T)))

macro attach*(fn: untyped): untyped =
   ## Insert the return type as a typedesc argument in the first position.
   fn.insert_type_param(copy(fn[3][0]))
   result = fn

macro attach*(T: untyped, fn: untyped): untyped =
   ## Insert `T` as a typedesc argument in the first position.
   fn.insert_type_param(T)
   result = fn
