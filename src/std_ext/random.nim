import
  ../std_ext

## https://en.cppreference.com/w/cpp/header/random

{.pass_c: "-std=c++11".}

when not defined(cpp):
  {.error: "random only support c++ backend".}

const H = "<random>"

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
  Ranlux24*{.import_cpp: "std::ranlux24",
             header: H.} = distinct DiscardBlockEngine
  Ranlux48*{.import_cpp: "std::ranlux48",
             header: H.} = distinct DiscardBlockEngine
  KnuthB*{.import_cpp: "std::knuth_b", header: H.} = distinct ShuffleOrderEngine
  DefaultRandomEngine*
    {.import_cpp: "std::default_random_engine", header: H.} = MinstdRand0
  RandomDevice*{.import_cpp: "std::random_device", header: H.} = object
  SeedSeq*{.import_cpp: "std::seed_seq", header: H.} = object
  UniformIntDistribution*[T: SomeInteger]
    {.import_cpp: "std::uniform_int_distribution<'0>", header: H.} = object
  UniformRealDistribution*[T: SomeFloat]
    {.import_cpp: "std::uniform_real_distribution<'0>", header: H.} = object
  BernoulliDistribution*
    {.import_cpp: "std::bernoulli_distribution", header: H.} = object
  BinomialDistribution*[T: SomeInteger]
    {.import_cpp: "std::binomial_distribution<'0>", header: H.} = object
  GeometricDistribution*[T: SomeInteger]
    {.import_cpp: "std::geometric_distribution<'0>", header: H.} = object
  NegativeBinomialDistribution*[T: SomeInteger]
    {.import_cpp: "std::negative_binomial_distribution<'0>", header: H.} = object
  PoissonDistribution*[T: SomeInteger]
    {.import_cpp: "std::poisson_distribution<'0>", header: H.} = object
  ExponentialDistribution*[T: SomeFloat]
    {.import_cpp: "std::exponential_distribution<'0>", header: H.} = object
  GammaDistribution*[T: SomeFloat]
    {.import_cpp: "std::gamma_distribution<'0>", header: H.} = object
  WeibullDistribution*[T: SomeFloat]
    {.import_cpp: "std::weibull_distribution<'0>", header: H.} = object
  ExtremeValueDistribution*[T: SomeFloat]
    {.import_cpp: "std::extreme_value_distribution<'0>", header: H.} = object
  NormalDistribution*[T: SomeFloat]
    {.import_cpp: "std::normal_distribution<'0>", header: H.} = object
  LogNormalDistribution*[T: SomeFloat]
    {.import_cpp: "std::lognormal_distribution<'0>", header: H.} = object
  ChiSquaredDistribution*[T: SomeFloat]
    {.import_cpp: "std::chi_squared_distribution<'0>", header: H.} = object
  CauchyDistribution*[T: SomeFloat]
    {.import_cpp: "std::cauchy_distribution<'0>", header: H.} = object
  FisherFDistribution*[T: SomeFloat]
    {.import_cpp: "std::fisher_f_distribution<'0>", header: H.} = object
  StudentTDistribution*[T: SomeFloat]
    {.import_cpp: "std::student_t_distribution<'0>", header: H.} = object
  DiscreteDistribution*[T: SomeInteger]
    {.import_cpp: "std::discrete_distribution<'0>", header: H.} = object
  PiecewiseConstantDistribution*[T: SomeFloat]
    {.import_cpp: "std::piecewise_constant_distribution<'0>",
      header: H.} = object
  PiecewiseLinearDistribution*[T: SomeFloat]
    {.import_cpp: "std::piecewise_linear_distribution<'0>", header: H.} = object

template templ_engine(EngineT: typedesc, ResultT: typedesc,
                      cpp_name: static string, BaseT: typedesc) =
  proc init*(self: typedesc[EngineT], value: ResultT): EngineT
    {.import_cpp: "std::" & cpp_name & "(##)", constructor, header: H.}

  proc seed*(self: var EngineT; value: ResultT)
    {.import_cpp: "#.seed(#)", header: H.}

  when BaseT isnot void:
    proc base*(self: EngineT): var BaseT
      {.import_cpp: "#.base()", header: H.}

  proc gen*(self: var EngineT): ResultT
    {.import_cpp: "#()", header: H.}

  proc discards*(self: var EngineT; z: culonglong)
    {.import_cpp: "#.discard(#)", header: H.}

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

proc init*(self: typedesc[RandomDevice]): RandomDevice
  {.import_cpp: "std::random_device()", constructor, header: H.}

proc gen*(self: RandomDevice): c_uint
  {.import_cpp: "#()", header: H.}

proc min*(self: typedesc[RandomDevice]): c_uint
  {.import_cpp: "std::random_device::min()", header: H.}

proc max*(self: typedesc[RandomDevice]): c_uint
  {.import_cpp: "std::random_device::max()", header: H.}

proc entropy*(self: RandomDevice): c_double
  {.import_cpp: "#.entropy()", header: H.}
