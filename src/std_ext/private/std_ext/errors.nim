import
   std/terminal
from std/macros import
   error

template init*[T: Exception](Self: typedesc[T], message: string,
                             parent_exception: ref Exception = nil): ref T =
   (ref Self)(msg: message, parent: parent_exception)

template throw*[T: Exception](Self: typedesc[T], message: string,
                              parent_exception: ref Exception = nil) =
   raise Self.init(message, parent_exception)

template failure*(msgs: openarray[string]) =
   write_stack_trace()
   styled_write(stderr, fg_red, "Failure:", fg_default, " ")
   for msg in msgs:
      stderr.write(msg)
   stderr.write('\n')
   quit(1)
