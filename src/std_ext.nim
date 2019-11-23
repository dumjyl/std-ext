import
   std_ext/macros,
   std_ext/private/std_ext/[iterators,
                            types,
                            attachs,
                            mem,
                            errors,
                            c_strs,
                            control_flow,
                            vec_like,
                            str]

export
   iterators,
   types,
   attachs,
   mem,
   errors,
   c_strs,
   control_flow,
   vec_like,
   str

from sugar import
   dump,
   `=>`,
   `->`
export
   dump,
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

proc init_ref*[T](val: T): ref T {.attach: T, inline.} =
   when T is ref:
      # new is specialized for ref so double the ref to avoid this.
      result = new(ref T)
   else:
      result = new(T)
   result[] = val

proc init_ptr*[T](val: T): ptr T {.attach: T, inline.} =
   result = create(T)
   result[] = val

proc gen_init_ref_or_ptr(T: Node, args: Node, call_str: string): Node =
   let sym = nsk_var.init("x")
   result = gen_stmts(gen_var_val(sym, gen_call(call_str, T)))
   var call = "init".gen_call(T)
   for arg in args:
      call.add(arg)
   result.add(nnk_asgn.init(nnk_deref_expr.init(sym), call))
   result.add(sym)
   result = gen_block(result)

macro init_ref*(T: typedesc[object], args: varargs[untyped]): ref =
   result = gen_init_ref_or_ptr(T, args, "new")

macro init_ptr*(T: typedesc[object], args: varargs[untyped]): ptr =
   result = gen_init_ref_or_ptr(T, args, "create")

when not compiles(low(u64)):
   proc low*[T: u32|u64|usize](PT: typedesc[T]): T =
      when size_of(T) == 8:
         result = cast[T](0'i64)
      elif size_of(T) == 4:
         result = cast[T](0'i32)
      else:
         {.error: "unsupported bitsize for low(u32|u64|usize)".}

   proc high*[T: u32|u64|usize](PT: typedesc[T]): T =
      when size_of(T) == 8:
         result = cast[T](-1'i64)
      elif size_of(T) == 4:
         result = cast[T](-1'i32)
      else:
         {.error: "unsupported bitsize for high(u32|u64|usize)".}

template deref*[T](x: ptr T): var T =
   ## Dereference `x`.
   x[]

template deref*[T](x: ref T): var T =
   ## Dereference `x`.
   x[]

proc bit_cast*[From, To](x: From, PTo: typedesc[To]): To {.inline.} =
   ## An alias for cast that takes a typedesc.
   result = cast[To](x)

proc bit_size_of*[T](PT: typedesc[T]): isize {.inline.} =
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

macro fixup_varargs*(call: untyped): untyped =
   ## Fix interaction between `varargs[typed]` and `varargs[untyped]`.
   ##
   ## This example silently discards arguments and segfaults.
   runnable_examples:
      template echo_vals(vals: varargs[untyped]) =
         echo vals
      template use_echo_vals(vals: varargs[typed]) =
        echo_vals('1', vals, 4)
      template use_echo_vals_fixed(vals: varargs[typed]) =
         fixup_varargs echo_vals('1', vals, 4)

      # use_echo_vals(2, "3") # segfaults.
      use_echo_vals_fixed(2, "3")
   call.needs_kind(nnk_call_kinds)
   var args = seq[Node].init()
   for arg in call:
      if arg.kind == nnk_hidden_std_conv and arg.len == 2 and
         arg[0].kind == nnk_empty and arg[1].kind == nnk_bracket:
         for arg in arg[1]:
            args.add(arg)
      else:
         args.add(arg)
   call.set_len(0)
   for arg in args:
      call.add(arg)
   result = call

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
