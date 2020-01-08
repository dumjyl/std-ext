import
   std_ext/macros,
   std_ext/private/std_ext/[iterators,
                            types,
                            mem,
                            errors,
                            control_flow,
                            vec_like,
                            str,
                            fixup_varargs]

when not defined(nim_script):
   import std_ext/private/std_ext/c_strs
   export c_strs

export
   iterators,
   types,
   mem,
   errors,
   control_flow,
   vec_like,
   str,
   fixup_varargs

from sugar import
   `=>`,
   `->`

export
   `=>`,
   `->`

proc `$`*(x: ref|ptr): string =
   runnable_examples:
      assert($default(ptr int) == "nil")
      assert($create(int) == "0")
   if x == nil:
      result = "nil"
   else:
      result = $x[]

proc init*[T](Self: type[ref T], val: T): ref T =
   # Creates a `ref Obj` from and `Obj`
   # XXX: (ref Generic).init(Generic[int](val: 1)) loses the generic arg.
   new(result)
   result[] = val

template init*[T](Self: type[ref T], args: varargs[untyped]): auto =
   # Creates a `ref Obj` from `Obj.init(args)`
   var res = new(ref type_of(init(type(T), args)))
   res[] = init(type(T), args)
   res

when not defined(nim_script):
   proc init*[T](Self: type[ptr T], val: T): ptr T =
      # Creates a `ptr Obj` from and `Obj`
      result = create(T)
      result[] = val

   template init*[T](Self: type[ptr T], args: varargs[untyped]): auto =
      # Creates a `ptr Obj` from `Obj.init(args)`
      var res = create(type_of(init(type(T), args)))
      res[] = init(type(T), args)
      res

template deref*[T](x: ptr T): var T =
   ## Dereference `x`.
   x[]

template deref*[T](x: ref T): var T =
   ## Dereference `x`.
   x[]

proc bit_cast*[From, To](x: From, PTo: type[To]): To {.inline.} =
   ## An alias for cast that takes a type.
   result = cast[To](x)

proc bit_size_of*[T](PT: type[T]): isize {.inline.} =
   ## Return the size in bits of a type.
   result = size_of(T) * 8

proc bit_size_of*[T](x: T): isize {.inline.} =
   ## Return the size in bits of an expression.
   result = size_of(x) * 8

template static_assert*(cond: untyped, msg = "") =
   ## A static version of `assert`.
   static: do_assert(cond, msg)

from os import parent_dir

template cur_src_dir*: untyped =
   parent_dir(instantiation_info(-1, true).filename)

template cur_src_file*: untyped =
   instantiation_info(-1, true).filename

proc add_tup*[T0, T1](self: var seq[(T0, T1)], a: T0, b: T1) =
   self.add((a, b))

template import_exists*(module: untyped): bool =
   compiles:
      import module

sec(test):
   type
      Obj = object
         str: string
         i32: int32
      RefObj = ref Obj
      AnonRefObj = ref object
         str: string
         i32: int32

run(test):
   block_of assert:
      $Obj(str: "obj str", i32: 3) == "(str: \"obj str\", i32: 3)"
      $RefObj(str: "ref obj str", i32: 7) == "(str: \"ref obj str\", i32: 7)"
      $AnonRefObj(str: "anon ref obj str", i32: 53) ==
         "(str: \"anon ref obj str\", i32: 53)"
      $default(ptr int) == "nil"
      $default(AnonRefObj) == "nil"
