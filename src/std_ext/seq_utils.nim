import
   ../std_ext,
   std/sequtils as sys_seq_utils

export
   sys_seq_utils

iterator combinations*(T: typedesc[enum], n: int): seq[T] {.inline.} =
   var counters = seq[T].init(n)
   for i in span(counters):
      counters[i] = low(T)
   loop outer:
      yield counters
      for i in span(counters):
         if counters[i] == high(T):
            if i == high(counters):
               break outer
            else:
               continue
         else:
            inc(counters[i])
            for j in span(i):
               counters[j] = low(T)
            break

proc combinations*(T: typedesc[enum], n: int): seq[seq[T]] =
   for combo in T.combinations(n):
      result.add(combo)

run(test):
   type Kind = enum A, B, C
   assert(Kind.combinations(3) == @[@[A, A, A], @[B, A, A], @[C, A, A],
                                    @[A, B, A], @[B, B, A], @[C, B, A],
                                    @[A, C, A], @[B, C, A], @[C, C, A],
                                    @[A, A, B], @[B, A, B], @[C, A, B],
                                    @[A, B, B], @[B, B, B], @[C, B, B],
                                    @[A, C, B], @[B, C, B], @[C, C, B],
                                    @[A, A, C], @[B, A, C], @[C, A, C],
                                    @[A, B, C], @[B, B, C], @[C, B, C],
                                    @[A, C, C], @[B, C, C], @[C, C, C]])
