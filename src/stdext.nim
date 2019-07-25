proc `$`*(x: ref|ptr): string =
  if x != nil:
    result = "ref " & $x[]
  else:
    result = "ref nil"

type
  LowHigh* = concept x
    low(x)
    high(x)

template span*(n: int): untyped =
  0 .. n

template span*(x: LowHigh): untyped =
  low(x) .. high(x)
