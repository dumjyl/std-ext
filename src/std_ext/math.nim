from std/math import
   sqrt

export
   sqrt

proc `^`*[T: SomeNumber](x: T, y: Natural): T =
   case y
   of 0: result = 1
   of 1: result = x
   of 2: result = x * x
   of 3: result = x * x * x
   else:
      var (x, y) = (x, y)
      result = 1
      while true:
         if (y and 1) != 0:
            result *= x
         y = y shr 1
         if y == 0:
            break
         x *= x
