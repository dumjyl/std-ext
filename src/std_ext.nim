import
   std_ext/macros,
   std_ext/private/std_ext/[iterators,
                            types,
                            mem,
                            exit_utils,
                            control_flow,
                            vec_like,
                            str,
                            fixup_varargs]

when not (defined(nim_script) or defined(js)):
   import std_ext/private/std_ext/c_strs
   export c_strs

export
   iterators,
   types,
   mem,
   exit_utils,
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

template deref*[T](x: ptr T): var T =
   ## Dereference `x`.
   x[]

template deref*[T](x: ref T): var T =
   ## Dereference `x`.
   x[]

template `deref=`*[T](x: ptr T, y: T) =
   x[] = y

template `deref=`*[T](x: ref T, y: T) =
   x[] = y

proc init*[T](Self: type[ref T], val: T): ref T =
   # Creates a `ref Obj` from and `Obj`
   # XXX: (ref Generic).init(Generic[int](val: 1)) loses the generic arg.
   new(result)
   result.deref = val

template init*[T](Self: type[ref T], args: varargs[untyped]): auto =
   # Creates a `ref Obj` from `Obj.init(args)`
   var result = new(ref type_of(init(type_of(T), args)))
   result.deref = init(type_of(T), args)
   result

template init*[T: Exception](Self: typedesc[T], message: string): ref T =
   (ref Self)(msg: message)

template throw*[T: Exception](Self: typedesc[T], message: string) =
   raise (ref Self)(msg: message)

when not defined(nim_script):
   proc init*[T](Self: type[ptr T], val: T): ptr T =
      # Creates a `ptr Obj` from and `Obj`
      result = create(T)
      result.deref = val

   template init*[T](Self: type[ptr T], args: varargs[untyped]): auto =
      # Creates a `ptr Obj` from `Obj.init(args)`
      var res = create(type_of(init(type_of(T), args)))
      res.deref = init(type_of(T), args)
      res

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
   ## Check if `module` can be imported.
   compiles:
      import module

template any*[T: enum](_: typedesc[T]): set[T] =
   ## Get a set of all values in `T`. Named `any` instead of `all` due because
   ## it is for use in a case statement.
   {low(T) .. high(T)}

section(test):
   type
      Obj = object
         str: string
         i32: int32
      RefObj = ref Obj
      AnonRefObj = ref object
         str: string
         i32: int32

anon_when(test):
   assert $Obj(str: "obj str", i32: 3) == "(str: \"obj str\", i32: 3)"
   assert $RefObj(str: "ref obj str", i32: 7) == "(str: \"ref obj str\", i32: 7)"
   assert $AnonRefObj(str: "anon ref obj str", i32: 53) ==
      "(str: \"anon ref obj str\", i32: 53)"
   assert $default(ptr int) == "nil"
   assert $default(AnonRefObj) == "nil"
