import
   ../std_ext,
   ./str_utils,
   std/[monotimes,
        times]

export monotimes
export times except `$`

proc current*: MonoTime {.attach.} =
   result = get_MonoTime()

proc nano_secs*: i64 {.attach: MonoTime.} =
   result = get_MonoTime().ticks()

proc init*(
      nanoseconds,
      microseconds,
      milliseconds,
      seconds,
      minutes,
      hours,
      days,
      weeks: i64 = 0
   ): Duration {.attach, inline.} =
   result = init_Duration(nanoseconds, microseconds, milliseconds, seconds,
                          minutes, hours, days, weeks)

proc `$`*(duration: Duration, to_unit = Nanoseconds): string =
   const unit_name = [
      Nanoseconds: "ns",
      Microseconds: "µs",
      Milliseconds: "ms",
      Seconds: "s",
      Minutes: "m",
      Hours: "h",
      Days: "d",
      Weeks: "w"]
   let parts = duration.to_parts()
   var str_parts = seq[string].init()
   for unit in rev(to_unit .. Weeks):
      if parts[unit] != 0:
         str_parts.add($parts[unit] & unit_name[unit])
   result = str_parts.join(", ")
