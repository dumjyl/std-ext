import
   ../../macros

#[
TODO: use this (explicit generic typedescs) when this is not ambiguous:
   type Set[T] = object
   proc foo[T: object|tuple](x: T) = discard
   proc foo[T0; T1: Set[T0]](x: T1) = discard
   foo(Set[int]())
proc insert_type_param(fn: Node, T: Node) =
   var typ_sym: Node
   if fn.generic_params.kind != nnk_empty and fn.generic_params.len > 0 and
         fn.generic_params[0][0] == T:
      typ_sym = T
   else:
      typ_sym = id"Self"
      if fn.generic_params.kind == nnk_empty:
         fn.generic_params = nnk_generic_params.init()
      fn.generic_params.add(gen_def_typ(typ_sym, T))
   fn.params.insert(1, gen_def_typ(nsk_param.init("self"),
                                   gen_typ(typedesc, typ_sym)))
]#

proc insert_type_param(fn: Node, T: Node) =
   fn.params.insert(1, gen_def_typ(id"Self", gen_typ(typedesc, T)))

macro attach*(fn: untyped): untyped =
   fn.insert_type_param(copy(fn[3][0]))
   result = fn

macro attach*(T: untyped, fn: untyped): untyped =
   fn.insert_type_param(T)
   result = fn
