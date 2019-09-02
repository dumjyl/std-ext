import
   ../std_ext,
   ../std_ext/[c_ffi, time, vec_ops]

export
   time

proc black_box*[T](value: T) {.inline.} =
   emit("""asm volatile("" : : "r,m"(""", value, """) : "memory");""")

proc report(name: string, nano_secs: seq[i64]) =
   echo name, " : ", mean(nano_secs.to(f64)),
              " : ", std_dev(nano_secs.to(f64))

template benchmark*(name: string, seconds: isize, body: untyped) =
   var nano_secs = seq[i64].of_cap(100_000)
   var total = MonoTime.nano_secs()
   block:
      for _ in 0 ..< 10000000:
         var iter = MonoTime.nano_secs()
         body
         nano_secs.add(MonoTime.nano_secs() - iter)
   report(name, nano_secs)
