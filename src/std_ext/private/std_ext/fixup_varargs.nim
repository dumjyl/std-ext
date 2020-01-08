import
   ../../macros,
   vec_like

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
   var args = seq[NimNode].init()
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
