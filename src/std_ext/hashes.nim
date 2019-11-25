import
   ../std_ext,
   ./mem_utils,
   std/bitops

# port of seahash: https://gitlab.redox-os.org/redox-os/seahash

static: assert(cpuEndian == littleEndian) # TODO: bigEndian support

{.push checks: off.}

proc read_int(x: ptr u8, len: isize): u64 =
   template rd(T: typedesc, offset = 0): u64 =
      x.offset_u8(offset).bit_cast(ptr T)[]
   result = case len:
   of 1: rd(u8)
   of 2: rd(u16)
   of 3: rd(u16).bit_or(rd(u8, 2) shl 16)
   of 4: rd(u32)
   of 5: rd(u32).bit_or(rd(u8, 4) shl 32)
   of 6: rd(u32).bit_or(rd(u16, 4) shl 32)
   of 7: rd(u32).bit_or(bit_or(rd(u16, 4) shl 32, rd(u8, 6) shl 48))
   else: 0'u64

proc read_u64(x: ptr u8): u64 =
   when size_of(isize) == 4:
      let ptr_u32 = x.bit_cast(ptr u32)
      result = bit_or(ptr_u32[].bit_cast(u64),
                      ptr_u32.offset(1)[].bit_cast(u64) shl 32)
   elif size_of(isize) == 8:
      result = x.bit_cast(ptr u64)[]
   else:
      {.error: "unsupported pointer size".}

proc diffuse(x: u64): u64 {.inline.} =
   var x = x * 0x6eed0e9da4d94a4f'u64
   let a = x shr 32
   let b = x shr 60
   x = bit_xor(x, a shr b)
   x = x * 0x6eed0e9da4d94a4f'u64
   result = x

proc undiffuse(x: u64): u64 {.inline.} =
   var x = x * 0x2f72b4215a3d8caf'u64
   let a = x shr 32
   let b = x shr 60
   x = bit_xor(x, a shr b)
   x = x * 0x2f72b4215a3d8caf'u64
   result = x

proc hash_buffer(x: openarray[u8],
                 a = 0x16f11fe89b0d677c'u64,
                 b = 0xb480a793d8e6c86c'u64,
                 c = 0x6fe2e5aaf078ebc9'u64,
                 d = 0x14f994a4c5259381'u64): u64 =
   var
      a = a
      b = b
      c = c
      d = d
      mem = x.unsafe_mem()
      mem_end = x.unsafe_mem().offset_u8(x.len.bit_and(bit_not(0x1F)))
   while mem_end > mem:
      template rd(state: u64, offset = 0) =
         state = state.bit_xor(read_u64(mem.offset_u8(offset)))
      rd(a)
      rd(b, 8)
      rd(c, 16)
      rd(d, 24)
      mem = mem.offset(32)
      a = diffuse(a)
      b = diffuse(b)
      c = diffuse(c)
      d = diffuse(d)
   var excessive = x.len.usize + x.unsafe_mem().bit_cast(usize) -
                   mem_end.bit_cast(usize)
   template rd_int(state: u64, offset = 0) =
      state = state.bit_xor(read_int(mem.offset_u8(offset), excessive.isize))
   template rd_u64(state: u64, offset = 0) =
      state = state.bit_xor(read_u64(mem.offset_u8(offset)))
   template df(state) =
      state = diffuse(state)
   case excessive:
   of 0: discard
   of 1..7:
      rd_int(a)
      df(a)
   of 8:
      rd_u64(a)
      df(a)
   of 9..15:
      rd_u64(a)
      excessive -= 8
      rd_int(b, 8)
      df(a)
      df(b)
   of 16:
      rd_u64(a)
      rd_u64(b, 8)
      df(a)
      df(b)
   of 17..23:
      rd_u64(a)
      rd_u64(b, 8)
      excessive -= 16
      rd_int(c, 16)
      df(a)
      df(b)
      df(c)
   of 24:
      rd_u64(a)
      rd_u64(b, 8)
      rd_u64(c, 16)
      df(a)
      df(b)
      df(c)
   else:
      rd_u64(a)
      rd_u64(b, 8)
      rd_u64(c, 16)
      excessive -= 24
      rd_int(d, 24)
      df(a)
      df(b)
      df(c)
      df(d)
   a = a.bit_xor(b)
   c = c.bit_xor(d)
   a = a.bit_xor(c)
   a = a.bit_xor(x.len.usize)
   result = diffuse(a)

sec(test):
   proc read_int_ref(x: openarray[u8]): u64 =
      for i in countdown(x.high, 0):
         result = result shl 8
         result = result.bit_or(x[i].bit_cast(u64))

   proc hash_buffer_ref(x: openarray[u8],
                        a = 0x16f11fe89b0d677c'u64,
                        b = 0xb480a793d8e6c86c'u64,
                        c = 0x6fe2e5aaf078ebc9'u64,
                        d = 0x14f994a4c5259381'u64): u64 =
      var state = (a: a, b: b, c: c, d: d)
      for i in countup(0, x.high, 8):
         var a = state.a
         a = diffuse(a.bit_xor(read_int_ref(x[i ..< min(i+8, x.len)])))
         state.a = state.b
         state.b = state.c
         state.c = state.d
         state.d = a
      result = diffuse(state.a.bit_xor(state.b)
                              .bit_xor(state.c)
                              .bit_xor(state.d)
                              .bit_xor(x.len.usize))

type
   HashEx* = u64
   Hasher* = object
      state: u64
      k1: u64
      k2: u64
      k3: u64
      k4: u64

proc init*(
      Self: type[Hasher],
      k1 = 0xe7b0c93ca8525013'u64,
      k2 = 0x011d02b854ae8182'u64,
      k3 = 0x7bcc5cf9c39cec76'u64,
      k4 = 0xfa336285d102d083'u64
      ): Hasher =
   ## Initialize a `Hasher` with 4 keys. Hash primitive values and buffers of
   ## primite values with the overloaded `mix` proc, then call `finish`.
   result = Hasher(state: bit_xor(k1, k3), k1: k1, k2: k2, k3: k3, k4: k4)

proc mix(hasher: var Hasher, x: u64, k1: u64, k2: u64) =
   hasher.state = bit_xor(hasher.state, bit_xor(x, k1))
   hasher.state = bit_xor(diffuse(hasher.state), k2)

proc mix*(hasher: var Hasher, x: u8) =
   hasher.mix(x.u64, hasher.k1, hasher.k3)

proc mix*(hasher: var Hasher, x: u16) =
   hasher.mix(x.u64, hasher.k2, hasher.k1)

proc mix*(hasher: var Hasher, x: u32) =
   hasher.mix(x.u64, hasher.k2, hasher.k3)

proc mix*(hasher: var Hasher, x: u64) =
   hasher.mix(x.u64, hasher.k1, hasher.k2)

proc mix*(hasher: var Hasher, x: usize) =
   hasher.mix(x.u64, hasher.k3, hasher.k2)

proc mix*(hasher: var Hasher, x: i8) =
   hasher.mix(x.u64, bit_not(hasher.k1), bit_not(hasher.k3))

proc mix*(hasher: var Hasher, x: i16) =
   hasher.mix(x.u64, bit_not(hasher.k2), bit_not(hasher.k1))

proc mix*(hasher: var Hasher, x: i32) =
   hasher.mix(x.u64, bit_not(hasher.k2), bit_not(hasher.k3))

proc mix*(hasher: var Hasher, x: i64) =
   hasher.mix(x.u64, bit_not(hasher.k1), bit_not(hasher.k2))

proc mix*(hasher: var Hasher, x: isize) =
   hasher.mix(x.u64, bit_not(hasher.k3), bit_not(hasher.k2))

proc mix*(hasher: var Hasher, x: pointer) =
   hasher.mix(x.bit_cast(usize))

proc mix*(hasher: var Hasher, x: openarray[u8]) =
   hasher.state = hasher.state.bit_xor(hash_buffer(x, hasher.k1, hasher.k2,
                                                   hasher.k3, hasher.k4))
   hasher.state = diffuse(hasher.state)

proc mix*(hasher: var Hasher, x: string) =
   hasher.mix(x.to_openarray_byte(0, x.len))

proc finish*(hasher: Hasher): HashEx =
   result = diffuse(hasher.state.bit_xor(hasher.k3)).bit_xor(hasher.k4)

template simple_hash(x: untyped): HashEx =
   var hasher = Hasher.init()
   hasher.mix(x)
   hasher.finish()

proc hash_ex*(x: string): HashEx =
   ## Hash a `string`.
   result = simple_hash(x)

proc hash_ex*(x: pointer): HashEx =
   ## Hash a `pointer`.
   result = simple_hash(x)

{.pop.}

sec(test):
   proc b(s: string): seq[u8] =
      for i in span(s):
         result.add(s[i].u8)

   proc read_int_test =
      var a = [2'u8, 3]
      var b = [3'u8, 2]
      var c = [3'u8, 2, 5]
      block_of assert:
         read_int(a.mem(), 2) == 770
         read_int(b.mem(), 2) == 515
         read_int(c.mem(), 3) == 328195

   proc read_u64_test =
      var a = [1'u8, 0, 0, 0, 0, 0, 0, 0]
      assert(read_u64(a.mem()) == 1)
      var b = [2'u8, 1, 0, 0, 0, 0, 0, 0]
      assert(read_u64(b.mem()) == 258)

   proc diffuse_test(x: u64, y: u64) =
      block_of assert:
         diffuse(x) == y
         x == undiffuse(y)
         undiffuse(diffuse(x)) == x

   proc hash_match(x: openarray[u8]) =
      template tst(a, b, c, d) =
         assert(hash_buffer(x, a, b, c, d) ==
                hash_buffer_ref(x, a, b, c, d), $x & " len " & $x.len &
                " prod: " & $hash_buffer(x) & ", ref: " & $hash_buffer_ref(x))
      assert(hash_buffer(x) == hash_buffer_ref(x), $x & " len " & $x.len &
             " prod: " & $hash_buffer(x) & ", ref: " & $hash_buffer_ref(x))
      tst(1'u64, 1'u64, 1'u64, 1'u64)
      tst(500'u64, 2873'u64, 2389'u64, 9283'u64)
      tst(238945723984'u64, 872894734'u64, 239478243'u64, 28937498234'u64)
      tst(bit_not(0'u64), bit_not(0'u64), bit_not(0'u64), bit_not(0'u64))
      tst(0'u64, 0'u64, 0'u64, 0'u64)

   proc zero =
      var arr: array[4096, u8]
      for n in span(arr):
         hash_match(arr[0..n])

   proc increasing =
      var arr: array[4096, u8]
      for i in span(arr):
         arr[i] = i.bit_cast(u8)
      hash_match(arr)

   proc position_depedent =
      var buf1: array[4098, u8]
      for i in span(buf1):
         buf1[i] = i.bit_cast(u8)
      var buf2: array[4098, u8]
      for i in span(buf2):
         buf2[i] = bit_xor(i.bit_cast(u8), 1)
      assert(hash_buffer(buf1) != hash_buffer(buf2))

   proc shakespear =
      hash_match(b"to be or not to be")
      hash_match(b"love is a wonderful terrible thing")

   proc zero_sensitive =
      var
         lhs0 = [1'u8, 2, 3, 4]
         lhs1 = [0'u8, 0, 0]
         rhs0 = [1'u8, 0, 2, 3, 4]
         rhs1 = [1'u8, 0, 0, 2, 3, 4]
         rhs2 = [1'u8, 2, 3, 4, 0]
         rhs3 = [0'u8, 1, 2, 3, 4]
         rhs4 = [0'u8, 0, 0, 0, 0]
      block_of assert:
         hash_buffer(lhs0) != hash_buffer(rhs0)
         hash_buffer(lhs0) != hash_buffer(rhs1)
         hash_buffer(lhs0) != hash_buffer(rhs2)
         hash_buffer(lhs0) != hash_buffer(rhs3)
         hash_buffer(lhs1) != hash_buffer(rhs4)

   proc not_equal() =
      block_of assert:
         hash_buffer(b"to be or not to be ") != hash_buffer(b"to be or not to be")
         hash_buffer(b"jkjke") != hash_buffer(b"jkjk")
         hash_buffer(b"ijkjke") != hash_buffer(b"ijkjk")
         hash_buffer(b"iijkjke") != hash_buffer(b"iijkjk")
         hash_buffer(b"iiijkjke") != hash_buffer(b"iiijkjk")
         hash_buffer(b"iiiijkjke") != hash_buffer(b"iiiijkjk")
         hash_buffer(b"iiiiijkjke") != hash_buffer(b"iiiiijkjk")
         hash_buffer(b"iiiiiijkjke") != hash_buffer(b"iiiiiijkjk")
         hash_buffer(b"iiiiiiijkjke") != hash_buffer(b"iiiiiiijkjk")
         hash_buffer(b"iiiiiiiijkjke") != hash_buffer(b"iiiiiiiijkjk")
         hash_buffer(b"ab") != hash_buffer(b"bb")

run(test):
   read_int_test()
   read_u64_test()
   diffuse_test(94203824938'u64, 17289265692384716055'u64)
   diffuse_test(0xDEADBEEF'u64, 12110756357096144265'u64)
   diffuse_test(0'u64, 0'u64)
   diffuse_test(1'u64, 15197155197312260123'u64)
   diffuse_test(2'u64, 1571904453004118546'u64)
   diffuse_test(3'u64, 16467633989910088880'u64)
   var abc = b"abc"
   assert(read_int(abc.mem(), 3) == read_int_ref(abc))
   assert(hash_buffer([1'u8, 2, 3, 4, 5, 6, 7, 8, 9]) ==
          hash_buffer_ref([1'u8, 2, 3, 4, 5, 6, 7, 8, 9]))
   assert(hash_buffer_ref(b"to be or not to be") == 1988685042348123509'u64)
   assert(hash_buffer(b"to be or not to be") == 1988685042348123509'u64)
   zero()
   position_depedent()
   shakespear()
   zero_sensitive()
   not_equal()
   increasing()
