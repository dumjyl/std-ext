import
   ../std_ext,
   build

## https://en.cppreference.com/w/cpp/header/random

const
   H = "<random>"

type
   LinearCongruentialEngine*
      {.import_cpp: "std::linear_congruential_engine" header: H.} = object
   MersenneTwisterEngine*
      {.import_cpp: "std::mersenne_twister_engine", header: H.} = object
   SubtractWithCarryEngine*
      {.import_cpp: "std::subtract_with_carry_engine", header: H.} = object
   DiscardBlockEngine*
      {.import_cpp: "std::discard_block_engine", header: H.} = object
   IndependentBitsEngine*
      {.import_cpp: "std::independent_bits_engine", header: H.} = object
   ShuffleOrderEngine*
      {.import_cpp: "std::shuffle_order_engine", header: H.} = object
   MinstdRand0*
      {.import_cpp: "std::minstd_rand0",
         header: H.} = distinct LinearCongruentialEngine
   MinstdRand*
      {.import_cpp: "std::minstd_rand",
         header: H.} = distinct LinearCongruentialEngine
   MT19937*
      {.import_cpp: "std::mt19937", header: H.} = distinct MersenneTwisterEngine
   MT19937_64*
      {.import_cpp: "std::mt19937_64",
         header: H.} = distinct MersenneTwisterEngine
   Ranlux24Base*
      {.import_cpp: "std::ranlux24_base",
         header: H.} = distinct SubtractWithCarryEngine
   Ranlux48Base*
      {.import_cpp: "std::ranlux48_base",
         header: H.} = distinct SubtractWithCarryEngine
   Ranlux24*
      {.import_cpp: "std::ranlux24", header: H.} = distinct DiscardBlockEngine
   Ranlux48*
      {.import_cpp: "std::ranlux48", header: H.} = distinct DiscardBlockEngine
   KnuthB*
      {.import_cpp: "std::knuth_b", header: H.} = distinct ShuffleOrderEngine
   DefaultRandomEngine*
      {.import_cpp: "std::default_random_engine", header: H.} = MinstdRand0
   RandomDevice* {.import_cpp: "std::random_device", header: H.} = object
   SeedSeq* {.import_cpp: "std::seed_seq", header: H.} = object
   UniformIntDist*[T: SomeInteger]
      {.import_cpp: "std::uniform_int_distribution<'0>", header: H.} = object
   UniformRealDist*[T: SomeFloat]
      {.import_cpp: "std::uniform_real_distribution<'0>", header: H.} = object
   BernoulliDist*
      {.import_cpp: "std::bernoulli_distribution", header: H.} = object
   BinomialDist*[T: SomeInteger]
      {.import_cpp: "std::binomial_distribution<'0>", header: H.} = object
   GeometricDist*[T: SomeInteger]
      {.import_cpp: "std::geometric_distribution<'0>", header: H.} = object
   NegativeBinomialDist*[T: SomeInteger]
      {.import_cpp: "std::negative_binomial_distribution<'0>",
         header: H.} = object
   PoissonDist*[T: SomeInteger]
      {.import_cpp: "std::poisson_distribution<'0>", header: H.} = object
   ExponentialDist*[T: SomeFloat]
      {.import_cpp: "std::exponential_distribution<'0>", header: H.} = object
   GammaDist*[T: SomeFloat]
      {.import_cpp: "std::gamma_distribution<'0>", header: H.} = object
   WeibullDist*[T: SomeFloat]
      {.import_cpp: "std::weibull_distribution<'0>", header: H.} = object
   ExtremeValueDist*[T: SomeFloat]
      {.import_cpp: "std::extreme_value_distribution<'0>", header: H.} = object
   NormalDist*[T: SomeFloat]
      {.import_cpp: "std::normal_distribution<'0>", header: H.} = object
   LogNormalDist*[T: SomeFloat]
      {.import_cpp: "std::lognormal_distribution<'0>", header: H.} = object
   ChiSquaredDist*[T: SomeFloat]
      {.import_cpp: "std::chi_squared_distribution<'0>", header: H.} = object
   CauchyDist*[T: SomeFloat]
      {.import_cpp: "std::cauchy_distribution<'0>", header: H.} = object
   FisherFDist*[T: SomeFloat]
      {.import_cpp: "std::fisher_f_distribution<'0>", header: H.} = object
   StudentTDist*[T: SomeFloat]
      {.import_cpp: "std::student_t_distribution<'0>", header: H.} = object
   DiscreteDist*[T: SomeInteger]
      {.import_cpp: "std::discrete_distribution<'0>", header: H.} = object
   PiecewiseConstantDist*[T: SomeFloat]
      {.import_cpp: "std::piecewise_constant_distribution<'0>",
         header: H.} = object
   PiecewiseLinearDist*[T: SomeFloat]
      {.import_cpp: "std::piecewise_linear_distribution<'0>", header: H.} = object

# --- Engines ---

template templ_engine(
      EngineT: typedesc,
      ResultT: typedesc,
      cpp_name: static string,
      BaseT: typedesc) =
   proc init*(Self: type[EngineT], value: ResultT): EngineT
      {.import_cpp: "std::" & cpp_name & "(@)", constructor, header: H.}

   proc seed*(self: EngineT; value: ResultT)
      {.import_cpp: "#.seed(@)", header: H.}

   when BaseT isnot void:
      proc base*(self: EngineT): var BaseT
         {.import_cpp: "#.base()", header: H.}

   proc sample*(self: EngineT): ResultT
      {.import_cpp: "#()", header: H.}

   proc discards*(self: EngineT; z: c_ulonglong)
      {.import_cpp: "#.discard(@)", header: H.}

   proc min*(self: typedesc[EngineT]): ResultT
      {.import_cpp: "std::" & cpp_name & "::min()", header: H.}

   proc max*(self: typedesc[EngineT]): ResultT
      {.import_cpp: "std::" & cpp_name & "::max()", header: H.}

templ_engine(MT19937, uint32, "mt19937", void)
templ_engine(MT19937_64, uint64, "mt19937_64", void)
templ_engine(MinstdRand0, uint32, "minstd_rand0", void)
templ_engine(MinstdRand, uint32, "minstd_rand", void)
templ_engine(Ranlux24Base, uint32, "ranlux24_base", void)
templ_engine(Ranlux48Base, uint64, "ranlux48_base", void)
templ_engine(Ranlux24, uint32, "ranlux24", Ranlux24Base)
templ_engine(Ranlux48, uint64, "ranlux48", Ranlux48Base)
templ_engine(KnuthB, uint32, "knuth_b", MinstdRand0)

# --- RandomDevice ---

proc init*(self: typedesc[RandomDevice]): RandomDevice
   {.import_cpp: "std::random_device()", constructor, header: H.}

proc sample*(self: RandomDevice): c_uint
   {.import_cpp: "#()", header: H.}

proc min*(self: typedesc[RandomDevice]): c_uint
   {.import_cpp: "std::random_device::min()", header: H.}

proc max*(self: typedesc[RandomDevice]): c_uint
   {.import_cpp: "std::random_device::max()", header: H.}

proc entropy*(self: RandomDevice): c_double
   {.import_cpp: "#.entropy()", header: H.}

# --- UniformInt ---

proc init*[T: SomeInteger](
      Self: type[UniformIntDist[T]],
      a: T,
      b: T
      ): UniformIntDist[T]
   {.import_cpp: "std::uniform_int_distribution<'*0>(@)", header: H.}

proc sample*[T: SomeInteger; G](self: UniformIntDist[T], gen: var G): T
   {.import_cpp: "#(@)", header: H.}

# --- UniformReal ---

proc init*[T: SomeFloat](
      Self: type[UniformRealDist[T]],
      a: T,
      b: T
      ): UniformRealDist[T]
   {.import_cpp: "std::uniform_real_distribution<'*0>(@)", header: H.}

proc sample*[T: SomeFloat; G](self: UniformRealDist[T], gen: var G): T
   {.import_cpp: "#(@)", header: H.}

# --- Uniform ---

type
   Uniform*[T] = object
      when T is SomeInteger:
         dist: UniformIntDist[T]
      else:
         dist: UniformRealDist[T]

proc init*[T: SomeNumber](Self: type[Uniform[T]], a: T, b: T): Uniform[T] =
   when T is SomeInteger:
      result = Uniform[T](dist: UniformIntDist.init(a, b))
   else:
      result = Uniform[T](dist: UniformRealDist.init(a, b))

proc sample*[T: SomeNumber; G](self: Uniform[T], gen: var G): T =
   result = self.dist.sample(gen)

# --- Normal ---

proc init*[T: SomeFloat](
      Self: type[NormalDist[T]],
      mean: T,
      std_dev: T
      ): NormalDist[T]
   {.import_cpp: "std::normal_distribution<'*0>(@)", header: H.}

proc sample*[T: SomeFloat; G](self: NormalDist[T], gen: G): T
   {.import_cpp: "#(@)", header: H.}

# --- helpers ---

proc init_rng*(): MT19937 =
   var rd = RandomDevice.init()
   result = MT19937.init(rd.sample())

var rng* = init_rng()

proc uniform*[T: SomeNumber](a: T, b: T): T =
   var dist = Uniform.init(a, b)
   result = dist.sample(rng)

proc uniform*[T: SomeNumber](params: Slice[T]): T =
   result = uniform(params.a, params.b)

proc uniform*[T: SomeNumber](
      Self: type[seq[T]],
      n: isize,
      a: T,
      b: T
      ): seq[T] =
   var dist = Uniform.init(a, b)
   result = seq[T].init(n)
   for i in span(n):
      result[i] = dist.sample(rng)

proc uniform*[T: SomeNumber](
      Self: type[seq[T]],
      n: isize,
      params: Slice[T]
      ): seq[T] =
   result = seq[T].uniform(params.a, params.b)

proc uniform*[T: SomeNumber](data: var openarray[T], a: T, b: T) =
   var dist = Uniform.init(a, b)
   for i in span(data):
      data[i] = dist.sample(rng)

proc uniform*[T: SomeNumber](data: var openarray[T], params: Slice[T]) =
   data.uniform(params.a, params.b)

proc normal*[T: SomeFloat](mean: T, std_dev: T): T =
   var dist = NormalDist.init(mean, std_dev)
   result = dist.sample(rng)

proc normal*[T: SomeFloat](data: var openarray[T], mean: T, std_dev: T): T =
   var dist = NormalDist.init(mean, std_dev)
   for i in span(data):
      result[i] = dist.sample(rng)

proc normal*[T: SomeFloat](
      Self: type[seq[T]],
      n: isize,
      mean: T,
      std_dev: T
      ): seq[T] =
   var dist = NormalDist.init(mean, std_dev)
   result = seq[T].init(n)
   for i in span(n):
      result[i] = dist.sample(rng)

proc shuffle*[T](data: var openarray[T]) =
   for i in span(data):
      var idx = uniform(0, data.high)
      if idx != i:
         swap(data[i], data[idx])

proc shuffled*[T](data: openarray[T]): seq[T] =
   result = seq[T].of_cap(data.len)
   var idxs = seq[T].init(data.len)
   for i in span(idxs):
      idxs[i] = i
   idxs.shuffle()
   for i in span(data):
      result.add(data[idxs[i]])
