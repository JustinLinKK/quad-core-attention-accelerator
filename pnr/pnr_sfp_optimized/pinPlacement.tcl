set topPins [list]
for {set lane 0} {$lane < 8} {incr lane} {
  set lane_base [expr {$lane * 22}]
  for {set bit 0} {$bit < 22} {incr bit} {
    lappend topPins [format {sfp_in[%d]} [expr {$lane_base + $bit}]]
  }
  for {set bit 0} {$bit < 22} {incr bit} {
    lappend topPins [format {sfp_out[%d]} [expr {$lane_base + $bit}]]
  }
}

set leftPins [list clk reset acc div multi_core div_done]

set rightPins [list ext_sum_wr ext_sum_empty]
for {set bit 0} {$bit < 28} {incr bit} {
  lappend rightPins [format {sum_in[%d]} $bit]
}
for {set bit 0} {$bit < 26} {incr bit} {
  lappend rightPins [format {sum_out[%d]} $bit]
}
lappend rightPins sum_valid

setPinAssignMode -pinEditInBatch true
editPin -pinWidth 0.1 -pinDepth 0.6 -fixedPin 1 -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Top -layer 3 -spreadType center -spacing 1.5 -pin $topPins

setPinAssignMode -pinEditInBatch true
editPin -pinWidth 0.1 -pinDepth 0.6 -fixedPin 1 -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Left -layer 3 -spreadType center -spacing 6 -pin $leftPins

setPinAssignMode -pinEditInBatch true
editPin -pinWidth 0.1 -pinDepth 0.6 -fixedPin 1 -fixOverlap 1 -unit MICRON -spreadDirection counterclockwise -side Right -layer 3 -spreadType center -spacing 4 -pin $rightPins
