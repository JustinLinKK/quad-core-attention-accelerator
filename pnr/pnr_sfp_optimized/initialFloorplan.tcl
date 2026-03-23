set core_width 1300
set core_height 400

# Keep the wide top edge under the SRAM and add vertical headroom for
# M1-M4 routing. Intended neighborhoods:
#   x=0..130      controller and control-side logic
#   x=130..1115   datapath and divider lanes
#   x=1115..1300  external-sum synchronizer and sum-side logic
#   y=340..400    top register band for SRAM-facing read/write traffic
floorPlan -s $core_width $core_height 2.5 2.5 2.5 2.5

globalNetConnect VDD -type pgpin -pin VDD -inst * -verbose
globalNetConnect VSS -type pgpin -pin VSS -inst * -verbose

#addRing -nets {VDD VSS} -type core_rings -layer {top M3 bottom M3 left M4 right M4} -width 2 -spacing 1 -center 1

setAddStripeMode -break_at {block_ring}

addStripe -nets {VDD VSS} -layer M4 -direction vertical -width 3 -spacing 6 -number_of_sets 20 -start_from left
sroute
