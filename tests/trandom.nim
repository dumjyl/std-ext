import
   ./std_ext,
   ./std_ext/random,
   std/sequtils

anon:
   var rd = RandomDevice.init()
   discard rd.entropy
   var x = MT19937_64.init(rd.sample())
   for _ in 0 ..< 50:
      discard x.sample()
   let real_dist = UniformRealDist.init(-5'f32, 10'f32)
   for _ in 0 ..< 50:
      discard real_dist.sample(rng)

   var y = to_seq(0 ..< 32)
   assert(y != y.shuffled())
