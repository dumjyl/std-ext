import
   ../std_ext,
   ./macros,
   ./flags,
   ./mem_utils,
   ./option,
   ./str_utils,
   std/strformat

from ./vec_ops import product

export
   flags

type
   TensorFlag = enum tf_invalid
   TensorDimPos = enum dim_shape_pos, dim_stride_pos, dim_offset_pos
   TensorDim = array[TensorDimPos, i32]
   TensorMetadata[N: static isize] = object
      dims: array[N, TensorDim]
      flags: Flags[TensorFlag]
   Tensor*[N: NI, T] = object
      data: RcData[T]
      metadata: TensorMetadata[N]
   TensorIndexSkip* = object
   StridedSlice[T] = object
      a, b, stride: T
   TensorReprOptions = object

const
   dim_ptr_pos = dim_shape_pos
   dim_kind_pos = dim_offset_pos
   max_dims* = 4
   skip* = TensorIndexSkip()

static_assert(size_of(Tensor[max_dims, f32]) <= 64)

# --- TensorDim ---

proc init*(
      shape: isize,
      stride: isize,
      offset: isize = 0
      ): TensorDim {.attach.} =
   result[dim_shape_pos] = shape.i32
   result[dim_stride_pos] = stride.i32
   result[dim_offset_pos] = offset.i32

proc init*(idxs: openarray[isize]): TensorDim {.attach.} =
   let idxs_data = RcData[i32].init(idxs.len)
   for i in span(idxs):
      idxs_data[i] = idxs[i]
   result[dim_ptr_pos].unsafe_set(idxs_data)
   result[dim_kind_pos] = -1

proc is_desc*(self: TensorDim): bool {.inline.} =
   result = self[dim_kind_pos] >= 0

proc is_idxs*(self: TensorDim): bool {.inline.} =
   result = self[dim_kind_pos] < 0

proc desc*(self: TensorDim): tuple[shape, stride, offset: i32] {.inline.} =
   assert(self.is_desc)
   result = self.bit_cast(tuple[shape, stride, offset: i32])

proc idxs*(self: TensorDim): RcData[i32] =
   assert(self.is_idxs)
   when size_of(pointer) == 8:
      result.unsafe_set([self[dim_ptr_pos], self[succ(dim_ptr_pos)]])
   elif size_of(pointer) == 4:
      result.unsafe_set(self[dim_ptr_pos])
   else:
      {.error: "unsupported pointer size".}

proc shape*(self: TensorDim): isize {.inline.} =
   assert(self.is_desc)
   result = self[dim_shape_pos].isize

proc `shape=`*(self: var TensorDim, val: isize) {.inline.} =
   assert(self.is_desc)
   self[dim_shape_pos] = val.i32

proc stride*(self: TensorDim): isize {.inline.} =
   assert(self.is_desc)
   result = self[dim_stride_pos].isize

proc `stride=`*(self: var TensorDim, val: isize) {.inline.} =
   assert(self.is_desc)
   self[dim_stride_pos] = val.i32

proc offset*(self: TensorDim): isize {.inline.} =
   assert(self.is_desc)
   result = self[dim_offset_pos].isize

proc `offset=`*(self: var TensorDim, val: isize) {.inline.} =
   assert(self.is_desc)
   self[dim_offset_pos] = val.i32

proc len*(self: TensorDim): isize {.inline.} =
   if self.is_desc:
      result = self.shape
   else:
      result = self.idxs.len

proc offset_contribution(self: TensorDim, i: isize): isize {.inline.} =
   if self.is_desc:
      result = self.offset
   else:
      result = self.idxs[i]

# --- TensorMetadata ---

proc init[N: NI](shape: array[N, isize]): TensorMetadata[N] {.attach.} =
   when N < 1 or N > max_dims: {.error: "invalid dimensionality: " & $N.}
   for i in rev(span(shape)):
      if i == shape.high:
         result.dims[i].stride = 1
      else:
         result.dims[i].stride = shape[i + 1] * result.dims[i + 1].stride
      result.dims[i].shape = shape[i]
      result.dims[i].offset = 0
   result.flags = Flags[TensorFlag].init()

proc init[
      N: NI](
      dims: array[N, TensorDim],
      flags = Flags[TensorFlag].init()
      ): TensorMetadata[N] {.attach.} =
   result.dims = dims
   result.flags = flags

# --- Tensor ---

proc `=destroy`[N: NI, T](self: var Tensor[N, T]) =
   if self.data != nil:
      dec_ref(self.data)

proc `=sink`[N: NI, T](dst: var Tensor[N, T], src: Tensor[N, T]) =
   `=destroy`(dst)
   dst.data = src.data
   dst.metadata = src.metadata

proc `=`[N: NI, T](dst: var Tensor[N, T], src: Tensor[N, T]) =
   inc_ref(src.data)
   `=destroy`(dst)
   dst.data = src.data
   dst.metadata = src.metadata

proc data[N: NI, T](self: Tensor[N, T]): RcData[T] =
   result = self.data

proc unsafe_get*[N: NI, T](self: Tensor[N, T], i: isize): T =
   result = self.data[i]

proc unsafe_set*[N: NI, T](self: Tensor[N, T], i: isize, val: T) =
   self.data[i] = val

proc init*[
      N: NI,
      T](
      shape: array[N, isize],
      allocator = get_local_allocator(),
      ): Tensor[N, T] {.attach.} =
   result.data = RcData[T].init(product(shape), allocator)
   result.metadata = TensorMetadata[N].init(shape)

proc init*[
      N: NI,
      T](
      data: RcData[T],
      metadata: TensorMetadata[N]
      ): Tensor[N, T] {.attach.} =
   inc_ref(data)
   result.data = data
   result.metadata = metadata

proc filled*[
      N: NI,
      T](
      shape: array[N, isize],
      val: T,
      allocator = get_local_allocator(),
      ): Tensor[N, T] {.attach.} =
   result = Tensor[N, T].init(shape, allocator)
   for i in span(result.data):
      result.data[i] = val

proc dim[N: NI, T](self: var Tensor[N, T], i: isize): var TensorDim {.inline.} =
   result = self.metadata.dims[i]

proc dim[N: NI, T](self: Tensor[N, T], i: isize): TensorDim {.inline.} =
   result = self.metadata.dims[i]

proc shape*[N: NI, T](self: Tensor[N, T], i: isize): isize {.inline.} =
   result = self.dim(i).len

proc shape*[N: NI, T](self: Tensor[N, T]): array[N, isize] =
   for i in span(N):
      result[i] = self.shape(i)

iterator shape*[N: NI, T](self: Tensor[N, T], i: isize): isize {.inline.} =
   var idx = 0
   while idx < self.shape(i):
      yield idx
      inc(idx)

proc stride*[N: NI, T](self: Tensor[N, T], i: isize): Opt[isize] =
   if self.dim(i).is_desc:
      result = some(self.dim(i).stride)
   else:
      result = none(isize)

proc stride*[N: NI, T](self: Tensor[N, T]): array[N, Opt[isize]] =
   for i in span(N):
      result[i] = self.stride(i)

proc offset*[N: NI, T](self: Tensor[N, T], i: isize): Opt[isize] =
   if self.dim(i).is_desc:
      result = some(self.dim(i).offset)
   else:
      result = none(isize)

proc offset*[N: NI, T](self: Tensor[N, T]): array[N, Opt[isize]] =
   for i in span(N):
      result[i] = self.offset(i)

type
   IndexKind = enum
      ik_int
      ik_array
      ik_seq
      ik_slice
      ik_strided_slice
      ik_skip
   IndexA = object
      kind: IndexKind
      ast: Node
      sym: Node

proc get_stride_expr(x_sym: Node, idx: Node, dim_idx: isize): Node =
   let dim = gen_call(bind_sym"dim", x_sym, gen_lit(dim_idx))
   result = quote do: (`idx` + offset(`dim`)) * stride(`dim`)

proc invalid_index_type(idx: Node) =
   error(&"invalid index type <{repr(idx.typ)}> for `{repr(idx)}`", idx)

proc get_idxs(stmts: Node, n_dims: isize, ast_idxs: Node): seq[IndexA] =
   for i, ast_idx in ast_idxs:
      var idx = IndexA(ast: ast_idx, sym: stmts.unalias(ast_idx, "idx" & $i))
      case ast_idx.typ_kind:
      of nty_int: idx.kind = ik_int
      else: invalid_index_type(ast_idx)
      result.add(idx)
   if result.len > n_dims:
      error(&"invalid index dimensionality; expected: 1 <= ND <= {n_dims}, " &
            &"got: {result.len}", ast_idxs)
   while result.len < n_dims:
      var skip_sym = bind_sym"skip"
      result.add(IndexA(kind: ik_skip, ast: skip_sym, sym: skip_sym))

proc get_output_shape(x_sym: Node, idxs: seq[IndexA]): Node =
   result = nnk_bracket.init()
   for i, idx in idxs:
      case idx.kind:
      of ik_array, ik_seq, ik_slice, ik_strided_slice:
         result.add(gen_call("len", idx.sym))
      of ik_skip:
         result.add(gen_call("shape", x_sym).gen_index(gen_lit(i)))
      of ik_int: discard

macro impl_index(
      x: Tensor,
      T: typedesc,
      n_dims: NI,
      ast_idxs: typed,
      ast_val: typed,
      ): untyped =
   result = gen_stmts()
   let is_getter = `type==`(ast_val.typ, get_type(None))
   let x_sym = result.unalias(x, "x")
   let idxs = get_idxs(result, n_dims, ast_idxs)
   let output_shape = get_output_shape(x_sym, idxs)
   if output_shape.len > 0:
      if is_getter:
      #    let y_sym = nsk_var.init("y")
      #    let n_lit = gen_lit(output_shape.len)
      #    var dims = nnk_bracket.init()
      #    var offset = gen_lit(0)
      #    for i, idx in idxs:
      #       case idx.kind:
      #       of ik_int:
      #          offset_expr = infix(
      #             offset_expr,
      #             "+",
      #             bind_call(
      #                "offset_contribution",
      #                bind_call("dim", gen_lit(i)),
      #                idx.sym))
      #       of ik_array, ik_seq, ik_slice, ik_strided_slice, ik_skip:
      #          bind_call("init", get_typ_inst(TensorDim), )
      #          offset = gen_lit(0)
      #    result.add(
      #       gen_var_val(
      #          y_sym,
      #          bind_call(
      #             "init",
      #             gen_gnrc(get_typ_inst(Tensor), n_lit, T),
      #             bind_call("data", x_sym),
      #             bind_call(
      #                "init",
      #                gen_gnrc(get_typ_inst(TensorMetadata), n_lit),
      #                dims))))
      #    result.add(y_sym)
         error"TODO: getter with non int indices"
      else:
         error"TODO: setter with non int indices"
   else:
      var idx_expr: Node
      for i, idx in idxs:
         var idx_expr_part = get_stride_expr(x_sym, idx.sym, i)
         if idx_expr == nil:
            idx_expr = idx_expr_part
         else:
            idx_expr = infix(idx_expr, "+", idx_expr_part)
      if is_getter:
         result.add(gen_call("unsafe_get", x_sym, idx_expr))
      else:
         result.add(gen_call("unsafe_set", x_sym, idx_expr, ast_val))
   if is_getter:
      result = gen_block(result)
   echo repr result

template `[]`*[
      N: NI,
      T](
      x: Tensor[N, T],
      idxs: varargs[typed]
      ): untyped =
   impl_index(x, x.T, N, idxs, None)

template `[]=`*[
      N: NI,
      T](
      x: Tensor[N, T],
      idxs: varargs[typed],
      val: typed
      ): untyped =
   impl_index(x, x.T, N, idxs, val)

# proc flatten

macro for_each[N: NI, T](self: Tensor[N, T], stmts: untyped): untyped =
   result = stmts
   for i in countdown(N - 1, 0):
      result = nnk_for_stmt.init(
         id("i" & $i),
         gen_call("shape", self, gen_lit(i)),
         result)
   echo result

proc init*(): TensorReprOptions {.attach.} =
   discard

var repr_options* = TensorReprOptions.init()

proc repr_impl[
      N: NI,
      T](
      self: Tensor[N, T],
      options: TensorReprOptions) =
   var strs = seq[string].init(self.shape(2) * self.shape(3))
   var str: string
   for i2 in self.shape(2):
      str &= "|"
      for i3 in self.shape(3):
         strs[i2 * self.shape(3) + i3].format_value(self[0, 0, i2, i3], "5")
         str.format_value(self[0, 0, i2, i3], "5")
      str &= "|\n"
   template horiz: string = '|' & "-".repeat(str.find("\n") - 2) & "|\n"
   echo horiz & str & horiz
   # echo "-".repeat(6 * self.shape(3) - 1)
   # for i2 in self.shape(2):

   # echo "|\n".repeat(self.shape(2))

proc `$`*[N: NI, T](self: Tensor[N, T], options = repr_options): string =
   repr_impl(self, options)
