import
   std_ext/colors,
   when_vm

template init*[T: Exception](Self: typedesc[T], message: string,
                             parent_exception: ref Exception = nil): ref T =
   (ref Self)(msg: message, parent: parent_exception)

template throw*[T: Exception](Self: typedesc[T], message: string,
                              parent_exception: ref Exception = nil) =
   raise (ref Self)(msg: message, parent: parent_exception)

template fatal*(msgs: varargs[string, `$`]) =
   when_vm:
      var msg_concat = red"Fatal:" & ' '
      for msg in msgs:
         msg_concat &= msg
      quit(msg_concat, 1)
   else:
      write_stack_trace()
      let prefix = red("Fatal:", stderr) & ' '
      stderr.write(prefix)
      for i in 0 ..< msgs.len: # XXX: varargs bug: items(msgs)
         stderr.write(msgs[i])
      stderr.write('\n')
      quit(1)
