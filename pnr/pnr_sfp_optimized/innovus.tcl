setMultiCpuUsage -localCpu 16
source loadDesignTech.tcl
source initialFloorplan.tcl
source pinPlacement.tcl
source placement.tcl
source clock.tcl
addFiller -cell {DCAP DCAP4 DCAP8 DCAP16 DCAP32} -merge true
source route.tcl
optDesign -postRoute -drv
optDesign -postRoute -inc
source reportDesign.tcl
source outputGen.tcl
