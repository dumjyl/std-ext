import
  ./std_ext

main_proc:
  var sum = 0
  visits(cur := 0):
    sum += cur
    if cur < 3:
      visit(cur + 1)
  assert(sum == 6)
