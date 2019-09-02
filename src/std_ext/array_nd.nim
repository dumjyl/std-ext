import
   ../std_ext,
   ./macros,
   ./anon,
   ./seq_utils,
   ./option,
   std/strformat

# TODO: switch to ref counted blob or COW to minimize copies
# TODO: use range type: N: ValidDims, when it works.
# TODO: ArrayView
# TODO: SkipSpan
# TODO: strided slicing
# TODO: determine if seq/indices are strided?
type
   ValidDims = range[1 .. 4]
   ArrayMetadata[N: static isize] = object
      shape: array[N, i32]
      stride: array[N, i32]
   Array*[T; N: static isize] = object
      data: seq[T]
      metadata: ArrayMetadata[N]
   ArrayIndexSkip* = object

const
   skip* = ArrayIndexSkip()

static: do_assert(size_of(Array[f32, 4]) <= 64)

# --- ArrayMetadata ---

proc init*[N: static isize](
      shape: array[N, isize]
      ): ArrayMetadata[N] {.attach.} =
   when low(ValidDims) < N or N > high(ValidDims):
      {.error: "invalid dimensionality: " & $N.}
   var len = 0
   for i in rev(span(shape)):
      if i == shape.high:
         result.stride[i] = 1
      else:
         result.stride[i] = shape[i + 1].i32 * result.stride[i + 1]
      result.shape[i] = shape[i].i32

proc len[N: static isize](metadata: ArrayMetadata[N]): isize =
   result = 1
   for i, size in metadata.shape:
      result *= size

# --- Array ---

proc init*[T; N: static isize](
           shape: array[N, isize]): Array[T, N] {.attach.} =
   result.metadata = ArrayMetadata.init(shape)
   result.data = seq[T].init(result.metadata.len)

proc len*[T; N: static isize](x: Array[T, N]): isize {.inline.} =
   result = x.data.len

proc shape*[T; N: static isize](x: Array[T, N]): array[N, isize] {.inline.} =
   for i, size in x.metadata.shape:
      result[i] = size

proc shape*[T; N: static isize](
      x: Array[T, N],
      dim: range[0 .. N-1]
      ): isize {.inline.} =
   result = x.metadata.shape[dim].isize

iterator shape*[T; N: static isize](
      x: Array[T, N],
      dim: range[0 .. N-1]
      ): isize {.inline.} =
   var i = 0
   while i < x.metadata.shape[dim]:
     yield i
     inc(i)

proc stride*[T; N: static isize](x: Array[T, N]): array[N, isize] {.inline.} =
   for i, size in x.metadata.stride:
      result[i] = size

proc stride*[T; N: static isize](
      x: Array[T, N],
      dim: range[0 .. N-1]
      ): isize {.inline.} =
   result = x.metadata.stride[dim].isize

proc data_copy*[T; N: static isize](x: Array[T, N]): seq[T] =
   result = x.data

proc unsafe_data*[T; N: static isize](x: Array[T, N]): ptr UncheckedArray[T] =
   result = x.data.unsafe_mem.bit_cast(ptr UncheckedArray[T])

proc mem*[T; N: static isize](x: var Array[T, N]): ptr T =
   result = x.data.mem()

proc unsafe_mem*[T; N: static isize](x: Array[T, N]): ptr T =
   result = x.data.unsafe_mem()

proc fill*[T; N: static isize](x: var Array[T, N], val: T) =
   for i in span(x.data):
      x.data[i] = val

proc filled*[T; N: static isize](shape: array[N, isize],
                                 val: T): Array[T, N] {.attach.} =
   result = Array[T, N].init(shape)
   result.fill(val)

proc zeros*[T; N: static isize](
            shape: array[N, isize]): Array[T, N] {.attach.} =
   result = Array[T, N].filled(shape, T(0))

proc ones*[T; N: static isize](shape: array[N, isize]): Array[T, N] {.attach.} =
   result = Array[T, N].filled(shape, T(1))

proc stride_expr(x: Node, lhs: Node, rhs: int): Node =
   result = infix(lhs, "*", gen_call("stride", x).gen_index(gen_lit(rhs)))

macro data(
      x: Array,
      N: static isize,
      idxs: varargs[isize]
      ): untyped =
   do_assert(N == idxs.len)
   for i in span(idxs):
      var idx_part: Node
      if i == idxs.high:
         idx_part = idxs[i]
      else:
         idx_part = x.stride_expr(idxs[i], i)
      result = if i == 0: idx_part else: infix(result, "+", idx_part)
   result = x.gen_dot("data").gen_index(result)

type
   IndexKind = enum
      IntIndex
      ArrayIndex
      SeqIndex
      SliceIndex
      SkipIndex
   Index = object
      kind: IndexKind
      ast: Node
      sym: Node

proc invalid_index_type(idx: Node) =
   error(&"invalid index type <{repr(idx.typ)}> for `{repr(idx)}`", idx)

proc get_idxs(result_ast: Node, n_dims: isize, ast_idxs: Node): seq[Index] =
   for i, idx_ast in ast_idxs:
      var idx = Index(ast: idx_ast,
                      sym: result_ast.unalias(idx_ast, "idx" & $i))
      case idx_ast.type_kind:
      of nty_int:
         idx.kind = IntIndex
      of nty_array, nty_sequence:
         if `type!=`(elem_typ(idx_ast.typ), isize):
            invalid_index_type(idx_ast)
         idx.kind = if idx_ast.type_kind == nty_array: ArrayIndex else: SeqIndex
      of nty_object:
         # TODO: verify HSlice elem types
         if `type==`(idx_ast.typ_inst, HSlice):
            idx.kind = SliceIndex
         elif `type==`(idx_ast.typ_inst, ArrayIndexSkip):
            idx.kind = SkipIndex
         else:
            invalid_index_type(idx_ast)
      else:
         invalid_index_type(idx_ast)
      result.add(idx)

   if result.len > n_dims:
      error(&"invalid index dimensionality; expected: 1 <= ND <= {n_dims}, " &
            &"got: {result.len}", ast_idxs)

   while result.len < n_dims:
      var skip_sym = bind_sym"skip"
      result.add(Index(kind: SkipIndex, ast: skip_sym, sym: skip_sym))

proc get_val(T: Node, ast_val: Node): Opt[Node] =
   if `id==`(ast_val, bind_sym"skip"):
      result = Node.none()
   # int lits are implicitly convertible
   elif ast_val.kind == nnk_int_lit or `type==`(T.typ[1], ast_val):
      result = Node.some(ast_val)
   else:
      error(&"invalid value type <{repr(ast_val.typ)}> for `{repr(ast_val)}`",
            ast_val)

proc get_y_shape(x_sym: Node, idxs: seq[Index]): Node =
   result = nnk_bracket.init()
   for i, idx in idxs:
      case idx.kind:
      of ArrayIndex, SeqIndex, SliceIndex:
         result.add(gen_call("len", idx.sym))
      of SkipIndex:
         result.add(gen_call("shape", x_sym).gen_index(gen_lit(i)))
      of IntIndex: discard

macro impl_index(
      x: Array,
      T: typedesc,
      n_dims: static isize,
      ast_idxs: typed,
      ast_val: typed,
      ): untyped =
   result = nnk_stmt_list.init()
   var x_sym = result.unalias(x, "x")
   var idxs = get_idxs(result, n_dims, ast_idxs)
   var y_shape = get_y_shape(x_sym, idxs)
   var opt_val = get_val(T, ast_val)

   if y_shape.len > 0:
      assert(false, "only integer indexing supported")
      var y_sym = gen_sym(nsk_var, "y")
      var y_typ = nnk_bracket_expr.init(id"Array", T, gen_lit(y_shape.len))
      result.add(gen_var_val(y_sym, gen_call("init", y_typ, y_shape)))
      var index_expr = gen_call("unsafe_data", x_sym).gen_index()
      var init_loops: Node
      for i in rev(span(idxs)):
         # var index_expr_part = (
         #    case infos[i].kind:
         #    of IntIndex: x_sym.stride_expr(infos[i].sym, i)
         #    of ArrayIndex:
         #    of SeqIndex:
         #    of SliceIndex:
         #    of SkipIndex: )
         # if i == high(infos):
         #    index_expr = 
         # else:
         # echo idxs[i]
         discard
      result.add(y_sym)
   else:
      var idx_expr: Node
      for i, idx in idxs:
         var idx_expr_part = stride_expr(x_sym, idx.sym, i)
         if idx_expr == nil:
            idx_expr = idx_expr_part
         else:
            idx_expr = infix(idx_expr, "+", idx_expr_part)
      var data_expr = gen_call("unsafe_data", x_sym).gen_index(idx_expr)
      result.add(if opt_val ?= val: gen_asgn(data_expr, val) else: data_expr)
   result = gen_block(result)
   # echo repr result

template `[]`*[T; N: static isize](
      x: Array[T, N],
      idxs: varargs[typed],
      ): untyped =
   impl_index(x, x.T, x.N, idxs, skip)

template `[]=`*[T; N: static isize](
      x: Array[T, N],
      idxs: varargs[typed],
      val: typed,
      ): untyped =
   impl_index(x, x.T, x.N, idxs, val)
