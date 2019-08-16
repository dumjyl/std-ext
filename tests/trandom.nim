import
  ./std_ext,
  ./std_ext/random

main_proc:
  var rd = RandomDevice.init()
  discard rd.entropy
  var x = MT19937_64.init(rd.gen())
  for i in 0 ..< 50:
    discard x.gen()