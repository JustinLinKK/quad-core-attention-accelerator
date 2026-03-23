set topPins [list]
for {set bit 0} {$bit < 64} {incr bit} {
  lappend topPins [format {D[%d]} $bit]
}

set bottomPins [list]
for {set bit 0} {$bit < 64} {incr bit} {
  lappend bottomPins [format {Q[%d]} $bit]
}

set leftPins [list CEN CLK WEN]
for {set bit 0} {$bit < 8} {incr bit} {
  lappend leftPins [format {A[%d]} $bit]
}

setPinAssignMode -pinEditInBatch true
editPin -pinWidth 0.1 -pinDepth 0.6 -fixedPin 1 -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Top -layer 4 -spreadType start -spacing 4.0 -start 7.5 500 -pin $topPins
setPinAssignMode -pinEditInBatch false

setPinAssignMode -pinEditInBatch true
editPin -pinWidth 0.1 -pinDepth 0.6 -fixedPin 1 -fixOverlap 1 -unit MICRON -spreadDirection counterclockwise -side Bottom -layer 4 -spreadType start -spacing 4.0 -start 7.5 0 -pin $bottomPins
setPinAssignMode -pinEditInBatch false

setPinAssignMode -pinEditInBatch true
editPin -pinWidth 0.1 -pinDepth 0.6 -fixedPin 1 -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side Left -layer 3 -spreadType center -spacing 4.0 -pin $leftPins
setPinAssignMode -pinEditInBatch false
