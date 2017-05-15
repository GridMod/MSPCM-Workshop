
##Run Magma

use a login node

```bash
cd ~
git clone https://github.com/NREL/MAGMA.git
cd /scratch/$USER/MSPCM-Workshop/Workshop-Explorations/TimeDomain_Decomp
module use /nopt/nrel/apps/modules/candidate/modulefiles
module purge
module load epel/6.6 R/3.2.2 pandoc/1.19.2.1
xvfb-run -a Rscript run_html_output.R
```
