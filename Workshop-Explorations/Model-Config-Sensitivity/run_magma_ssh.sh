#! /bin/bash

echo $PWD
module use /nopt/nrel/apps/modules/candidate/modulefiles
module purge
module load epel/6.6 R/3.2.2 pandoc/1.19.2.1
xvfb-run -a Rscript run_html_output_rts_DA.R
xvfb-run -a Rscript run_html_output_rts_DA_RT.R
