
##Run Magma

```bash
cd /scratch/wjones/
git clone https://github.com/NREL/MAGMA.git
cd MAGMA/Examples/RTS-2016
module use /nopt/nrel/apps/modules/candidate/modulefiles
module purge
module load epel/6.6 R/3.2.2 pandoc/1.19.2.1
vi run_html_output.R # fix magma.dir to point to $PWD/../.. 
xvfb-run -a Rscript run_html_output.R
```
