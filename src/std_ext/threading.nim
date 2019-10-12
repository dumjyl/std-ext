import
   ../std_ext,
   ./macros,
   std/concurrency/atomics

export atomics

when not compile_option("threads"):
   {.error: "must be compiled with --threads:on".}

export
   type_of_or_void

proc init*(Self: typedesc[Thread[void]], fn: proc {.nim_call.}): Thread[void] =
   result.create_thread(fn)

macro init*(Self: typedesc[Thread], fn_call: typed): Thread =
   fn_call.needs_kind(nnk_call_kinds)
   fn_call.needs_len(1 .. 2)
   let tmp_sym = nsk_var.init("thread_tmp")
   let fn = fn_call[0]
   if fn_call.len == 2:
      let val = fn_call[1]
      result = quote do:
         block:
            var `tmp_sym`: Thread[type_of_or_void(`val`)]
            `tmp_sym`.create_thread(`fn`, `val`)
            `tmp_sym`
   else:
      fn_call.needs_kind(nty_void)
      result = quote do:
         block:
            var `tmp_sym`: Thread[void]
            `tmp_sym`.create_thread(`fn`)
            `tmp_sym`

proc `$`*[T](self: var Atomic[T]): string =
   result = $self.load()
