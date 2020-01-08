import
   std_ext/colors

template init*[T: Exception](Self: typedesc[T], message: string,
                             parent_exception: ref Exception = nil): ref T =
   (ref Self)(msg: message, parent: parent_exception)

template throw*[T: Exception](Self: typedesc[T], message: string,
                              parent_exception: ref Exception = nil) =
   raise (ref Self)(msg: message, parent: parent_exception)

template vm_fatal(msgs: varargs[string]) =
   var msg_concat = red"Fatal:" & ' '
   for msg in msgs:
      msg_concat &= msg
   quit(msg_concat, 1)

template fatal*(msgs: varargs[string, `$`]) =
   when nim_vm:
      vm_fatal msgs
   else:
      when defined(nim_script):
         vm_fatal msgs
      else:
         write_stack_trace()
         let prefix = red("Fatal:", stderr) & ' '
         stderr.write(prefix)
         for i in 0 ..< msgs.len: # XXX: varargs bug: items(msgs)
            stderr.write(msgs[i])
         stderr.write('\n')
         quit(1)
