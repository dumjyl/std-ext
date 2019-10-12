import
   std_ext/threading

proc hello(n: int) {.thread.} =
   for i in 0 ..< n:
      echo "Hello ", i

proc hello {.thread.} =
   echo "Hello void"

Thread.init(hello(5)).join_thread()
Thread.init(hello()).join_thread()

