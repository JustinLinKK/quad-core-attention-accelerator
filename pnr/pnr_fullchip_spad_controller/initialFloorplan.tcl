# Floorplan the controller as a left-edge companion block:
# narrow in X, tall in Y, with enough right-edge perimeter for the
# scratchpad/core buses and a target placement density of 0.60.
set controller_stdcell_area 1484
set target_density 0.60
set target_core_area [expr {$controller_stdcell_area / $target_density}]

set core_width 20
set core_height [expr {$target_core_area / $core_width}]
set die_margin 5.0

floorPlan -s $core_width $core_height $die_margin $die_margin $die_margin $die_margin

globalNetConnect VDD -type pgpin -pin VDD -inst * -verbose
globalNetConnect VSS -type pgpin -pin VSS -inst * -verbose

setAddStripeMode -break_at {block_ring}

# Keep PG simple so the narrow controller channel still routes cleanly.
addStripe -nets {VDD VSS} -layer M4 -direction vertical -width 2.0 -spacing 4.0 \
    -number_of_sets 2 -start_from left

sroute
