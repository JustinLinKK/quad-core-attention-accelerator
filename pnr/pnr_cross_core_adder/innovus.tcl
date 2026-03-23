setMultiCpuUsage -localCpu 16
setUsefulSkewMode -maxSkew true -allNegEndPoints true
source loadDesignTech.tcl
source initialFloorplan.tcl
source pinPlacement.tcl
source placement.tcl
optDesign -preCTS
source clock.tcl
source addFiller.tcl
source route.tcl
optDesign -postRoute -drv
optDesign -postRoute -inc
source reportDesign.tcl
source outputGen.tcl
