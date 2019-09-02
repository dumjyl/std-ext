import
   ../std_ext,
   ./macros,
   ./math,
   ./anon

proc to*[From, To](xs: openarray[From], _: typedesc[To]): seq[To] =
   result = seq[To].init(xs.len)
   for i in span(xs):
      when compiles(To(xs[i])):
         result[i] = To(xs[i])
      else:
         result[i] = xs[i].to(To)

# --- maps ---

template check_dims(a, b) =
   if unlikely(a.len != b.len):
      IndexError.throw("a.len != b.len : " & $a.len & " != " & $b.len)

macro gen_op(
      op: untyped,
      TA: typedesc,
      TB: typedesc = None,
      TY: typedesc = None,
      ): untyped =
   result = gen_stmts()
   for is_array in bool:
      for a_is_vec in bool:
         for b_is_vec in bool:
            if not a_is_vec and not b_is_vec: continue
            var a_sym = id"a"
            var b_sym = id"b"
            var gnrcs: seq[Node]
            if is_array:
               gnrcs.add(gen_def_typ(id"N", gen_gnrc(id"static", id"isize")))
            var a_elem_typ = TA
            if TA.typ[1].typ_kind == nty_or:
               gnrcs.add(gen_def_typ(id"T0", TA))
               a_elem_typ = id"T0"
            var b_elem_typ = TB
            if `type==`(TB.typ[1], None): b_elem_typ = a_elem_typ
            var ret_typ = TY
            if `type==`(TY.typ[1], None): ret_typ = a_elem_typ
            ret_typ = if is_array: gen_gnrc(id"array", id"N", ret_typ)
                      else: gen_gnrc(id"seq", ret_typ)
            template arg_typ(x: untyped) =
               var `x typ` {.inject.} = `x elem_typ`
               if `x is_vec`:
                  `x typ` = if is_array: gen_gnrc(id"array", id"N", `x typ`)
                            else: gen_gnrc(id"openarray", `x typ`)
            arg_typ(a)
            arg_typ(b)
            var body = gen_stmts()
            if not is_array:
               if a_is_vec and b_is_vec:
                  body.add(get_ast(check_dims(a_sym, b_sym)))
               var len_sym = if a_is_vec: a_sym else: b_sym
               body.add(quote do: result = `ret_typ`.init(len(`len_sym`)))
            var i = id"i"
            var a = if a_is_vec: a_sym.copy.gen_index(i) else: a_sym
            var b = if b_is_vec: b_sym.copy.gen_index(i) else: b_sym
            body.add quote do:
               for `i` in span(result):
                  result[`i`] = `op`(`a`, `b`)
            result.add(gen_proc(id(op.str, true, [], true),
                                [gen_def_typ(a_sym, a_typ),
                                 gen_def_typ(b_sym, b_typ)],
                                ret_typ, gnrcs, body))

gen_op(`+`, SomeNumber)
gen_op(`-`, SomeNumber)
gen_op(`*`, SomeNumber)
gen_op(`/`, SomeFloat)
gen_op(`/`, isize, TY = float)
gen_op(`div`, SomeInteger)
gen_op(`mod`, SomeInteger)
gen_op(`^`, SomeNumber, Natural)

# --- reductions ---

proc sum*[T: SomeNumber](xs: openarray[T]): T =
   result = T(0)
   for x in xs:
      result += x

proc product*[T: SomeNumber](xs: openarray[T]): T =
   result = xs[0]
   for i in 1 ..< xs.len:
      result *= xs[i]

proc mean*[T: SomeFloat](xs: openarray[T]): T =
   result = sum(xs) / T(xs.len)

proc std_dev*[T: SomeFloat](xs: openarray[T]): T =
   result = sqrt(sum((xs - mean(xs)) ^ 2) / T(xs.len - 1))
