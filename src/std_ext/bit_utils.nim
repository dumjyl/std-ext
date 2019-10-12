import
   ../std_ext,
   ./str_utils,
   std/bitops

export
   bitops

proc repr_bin*(x: pointer|SomeNumber): string =
   result = string.init(bit_size_of(x))
   when x is pointer:
      var x = x.bit_cast(usize)
   for i in rev(span(result)):
      result[^(i+1)] = if bit_and(x shr i, 1) == 0: '0' else: '1'

proc repr_hex*(x: pointer|SomeNumber): string =
   when x is pointer:
      var x = x.bit_cast(usize)
   result = to_hex(x)
