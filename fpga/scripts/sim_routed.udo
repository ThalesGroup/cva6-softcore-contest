power add -in -inout -internal -out -r /tb_cva6_zybo_z7_20/DUT/*
run 100ms
power report -all -bsaif ../../../../../work-sim/routed.saif
exit
