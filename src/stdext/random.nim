import
  ../stdext

## https://en.cppreference.com/w/cpp/header/random

{.passC: "-std=c++11".}

when not defined(cpp):
  {.error: "random only support c++ backend".}

const H = "<random>"

type
  LinearCongruentialEngine*
    {.importcpp: "std::linear_congruential_engine" header: H.} = object
  MersenneTwisterEngine*
    {.importcpp: "std::mersenne_twister_engine", header: H.} = object
  SubtractWithCarryEngine*
    {.importcpp: "std::subtract_with_carry_engine", header: H.} = object
  DiscardBlockEngine*
    {.importcpp: "std::discard_block_engine", header: H.} = object
  IndependentBitsEngine*
    {.importcpp: "std::independent_bits_engine", header: H.} = object
  ShuffleOrderEngine*
    {.importcpp: "std::shuffle_order_engine", header: H.} = object
  MinstdRand0*
    {.importcpp: "std::minstd_rand0",
      header: H.} = distinct LinearCongruentialEngine
  MinstdRand*
    {.importcpp: "std::minstd_rand",
      header: H.} = distinct LinearCongruentialEngine
  MT19937*
    {.importcpp: "std::mt19937", header: H.} = distinct MersenneTwisterEngine
  MT19937_64*
    {.importcpp: "std::mt19937_64",
      header: H.} = distinct MersenneTwisterEngine
  Ranlux24Base*
    {.importcpp: "std::ranlux24_base",
      header: H.} = distinct SubtractWithCarryEngine
  Ranlux48Base*
    {.importcpp: "std::ranlux48_base",
      header: H.} = distinct SubtractWithCarryEngine
  Ranlux24*{.importcpp: "std::ranlux24",
             header: H.} = distinct DiscardBlockEngine
  Ranlux48*{.importcpp: "std::ranlux48",
             header: H.} = distinct DiscardBlockEngine
  KnuthB*{.importcpp: "std::knuth_b", header: H.} = distinct ShuffleOrderEngine
  DefaultRandomEngine*
    {.importcpp: "std::default_random_engine", header: H.} = MinstdRand0
  RandomDevice*{.importcpp: "std::random_device", header: H.} = object
  SeedSeq*{.importcpp: "std::seed_seq", header: H.} = object
  UniformIntDistribution*[T: SomeInteger]
    {.importcpp: "std::uniform_int_distribution<'0>", header: H.} = object
  UniformRealDistribution*[T: SomeFloat]
    {.importcpp: "std::uniform_real_distribution<'0>", header: H.} = object
  BernoulliDistribution*
    {.importcpp: "std::bernoulli_distribution", header: H.} = object
  BinomialDistribution*[T: SomeInteger]
    {.importcpp: "std::binomial_distribution<'0>", header: H.} = object
  GeometricDistribution*[T: SomeInteger]
    {.importcpp: "std::geometric_distribution<'0>", header: H.} = object
  NegativeBinomialDistribution*[T: SomeInteger]
    {.importcpp: "std::negative_binomial_distribution<'0>", header: H.} = object
  PoissonDistribution*[T: SomeInteger]
    {.importcpp: "std::poisson_distribution<'0>", header: H.} = object
  ExponentialDistribution*[T: SomeFloat]
    {.importcpp: "std::exponential_distribution<'0>", header: H.} = object
  GammaDistribution*[T: SomeFloat]
    {.importcpp: "std::gamma_distribution<'0>", header: H.} = object
  WeibullDistribution*[T: SomeFloat]
    {.importcpp: "std::weibull_distribution<'0>", header: H.} = object
  ExtremeValueDistribution*[T: SomeFloat]
    {.importcpp: "std::extreme_value_distribution<'0>", header: H.} = object
  NormalDistribution*[T: SomeFloat]
    {.importcpp: "std::normal_distribution<'0>", header: H.} = object
  LogNormalDistribution*[T: SomeFloat]
    {.importcpp: "std::lognormal_distribution<'0>", header: H.} = object
  ChiSquaredDistribution*[T: SomeFloat]
    {.importcpp: "std::chi_squared_distribution<'0>", header: H.} = object
  CauchyDistribution*[T: SomeFloat]
    {.importcpp: "std::cauchy_distribution<'0>", header: H.} = object
  FisherFDistribution*[T: SomeFloat]
    {.importcpp: "std::fisher_f_distribution<'0>", header: H.} = object
  StudentTDistribution*[T: SomeFloat]
    {.importcpp: "std::student_t_distribution<'0>", header: H.} = object
  DiscreteDistribution*[T: SomeInteger]
    {.importcpp: "std::discrete_distribution<'0>", header: H.} = object
  PiecewiseConstantDistribution*[T: SomeFloat]
    {.importcpp: "std::piecewise_constant_distribution<'0>",
      header: H.} = object
  PiecewiseLinearDistribution*[T: SomeFloat]
    {.importcpp: "std::piecewise_linear_distribution<'0>", header: H.} = object

template templEngine(EngineT, ResultT: typedesc; cppname: static string;
                     BaseT: typedesc) =
  proc init*(self: typedesc[EngineT]; value: ResultT): EngineT
    {.importcpp: "std::" & cppname & "(##)", constructor, header: H.}

  proc seed*(self: var EngineT; value: ResultT)
    {.importcpp: "#.seed(#)", header: H.}

  when BaseT isnot void:
    proc base*(self: EngineT): var BaseT
      {.importcpp: "#.base()", header: H.}

  proc gen*(self: var EngineT): ResultT
    {.importcpp: "#()", header: H.}

  proc discards*(self: var EngineT; z: culonglong)
    {.importcpp: "#.discard(#)", header: H.}

  proc min*(self: typedesc[EngineT]): ResultT
    {.importcpp: "std::" & cppname & "::min()", header: H.}

  proc max*(self: typedesc[EngineT]): ResultT
    {.importcpp: "std::" & cppname & "::max()", header: H.}

templEngine(MT19937, uint32, "mt19937", void)
templEngine(MT19937_64, uint64, "mt19937_64", void)
templEngine(MinstdRand0, uint32, "minstd_rand0", void)
templEngine(MinstdRand, uint32, "minstd_rand", void)
templEngine(Ranlux24Base, uint32, "ranlux24_base", void)
templEngine(Ranlux48Base, uint64, "ranlux48_base", void)
templEngine(Ranlux24, uint32, "ranlux24", Ranlux24Base)
templEngine(Ranlux48, uint64, "ranlux48", Ranlux48Base)
templEngine(KnuthB, uint32, "knuth_b", MinstdRand0)

proc init*(self: typedesc[RandomDevice]): RandomDevice
  {.importcpp: "std::random_device()", constructor, header: H.}

proc gen*(self: RandomDevice): cuint
  {.importcpp: "#()", header: H.}

proc min*(self: typedesc[RandomDevice]): cuint
  {.importcpp: "std::random_device::min()", header: H.}

proc max*(self: typedesc[RandomDevice]): cuint
  {.importcpp: "std::random_device::max()", header: H.}

proc entropy*(self: RandomDevice): cdouble
  {.importcpp: "#.entropy()", header: H.}

testFn:
  var rd = RandomDevice.init()
  discard rd.entropy
  var x = MT19937_64.init(rd.gen())
  for i in 0 ..< 50:
    discard x.gen()