import
   ../std_ext,
   std/[monotimes, times]

export
   monotimes,
   times

proc current*: MonoTime {.attach.} =
   result = get_MonoTime()

proc nano_secs*: i64 {.attach: MonoTime.} =
   result = get_MonoTime().ticks()
