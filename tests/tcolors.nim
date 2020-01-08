import std_ext/colors

template ln(color) =
   echo color("xxx") & "-" &
        `bright color`("xxx") & "-" &
        color("xxx").`bg_bright color` & "-" &
        `bright color`("xxx").`bg color`

template echo_colors {.dirty.} =
   ln black
   ln red
   ln green
   ln yellow
   ln blue
   ln magenta
   ln cyan
   ln white

static: echo_colors
echo_colors
