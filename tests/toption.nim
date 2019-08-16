import
  ./std_ext,
  ./std_ext/option

main_proc:
  assert(size_of(Option[i8]) == 2)
  assert(size_of(Option[ref i8]) == 8)
  type MaybeFloat = Option[ref f32]
  var x: ref f32
  do_assert_raises OptionError: discard MaybeFloat.init(x)
  do_assert_raises OptionError: discard Option.init(x)
  do_assert_raises OptionError: discard Option[ref f32].init(x)
  var y = new(f32)

  var a_nil = Option[string].none()
  assert($a_nil == "none(string)")
  assert(a_nil.is_none())
  var b_nil = Option[ref f32].none()
  assert(b_nil.is_none())
  var a_has = Option.init("str")
  assert($a_has == "value(str)")
  assert(a_has.is_val())
  var b_has = Option.init(y)
  assert(b_has.is_val())

  if a_has ?= str:
    assert(str == "str")

  var nil_path = false
  assert((if a_nil ?= str: "str" else: "nil str") == "nil str")

  type
    IntsResult = Result[int, int]
    UnitResult = Result[Unit, int]
  var
    a = IntsResult.init(3)
    b = Result[int, int].init(4)
    c = UnitResult.init()
    d = Result[Unit, int].init()
  block_of assert:
    a.is_ok()
    b.is_ok()
    c.is_ok()
    d.is_ok()
    $c == "ok(())"
  a = IntsResult.err(3)
  b = Result[int, int].err(4)
  c = UnitResult.err(5)
  d = Result[Unit, int].err(6)
  block_of assert:
    a.is_err()
    b.is_err()
    c.is_err()
    d.is_err()
    $c == "error(5)"

  type ErrorKinds = enum OutOfMem, Uninitialized, SomethingElse
  for res in [Result[int, ErrorKinds].init(3),
              Result[int, ErrorKinds].err(OutOfMem)]:
    unpack res:
    of val := T:
      assert(val == 3)
    of err := E:
      assert(err == OutOfMem)