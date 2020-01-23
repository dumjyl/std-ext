import pkg/std_ext

proc inner =
   fatal("this is a bad msg")

proc cleanup =
   echo "run cleanup"

main cleanup:
   inner()
