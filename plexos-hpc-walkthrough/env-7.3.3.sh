module use /nopt/nrel/apps/modules/candidate/modulefiles
module purge
module load epel gcc mono/4.6.2.7 xpressmp/7.8.0 plexos/7.300.3
module load conda
module load coad
export PLEXOS_TEMP=/scratch/$USER/tmp/$PBS_JOBID
export TEMP=$PLEXOS_TEMP
mkdir -p $PLEXOS_TEMP
