# Running RTS-GMLC Example Workflow

1. Move into the model directory
 ```
 cd /scratch/$USER/MSPCM-Workshop/Workshop-Explorations/OneWeek
 ```

2. Create a symbolic link to the timeseries datafiles, environment and python script
 ```
 ln -s ../../RTS-GMLC-Dataset/timeseries_data_files timeseries_data_files
 ln -s ../../plexos-hpc-walkthrough/env-7.3.3.sh .
 ln -s ../../plexos-hpc-walkthrough/get_week.py .
 ```

3. Get yourself an interactive node
 ```
 qsub -I -A PLEXOSMODEL -l advres=workshop.57684,nodes=1,walltime=1:30:00 -q batch-h
 # without a reservation this looks like qsub -I -A PLEXOSMODEL -q debug
 ```
 
4. Setup your environment
 ```
source env-7.3.3.sh

#module use /nopt/nrel/apps/modules/candidate/modulefiles
#module purge
#module load epel gcc mono/4.6.2.7 xpressmp/7.8.0 plexos/7.300.3
#module load conda
#module load coad
#export PLEXOS_TEMP=/scratch/$USER/tmp/$PBS_JOBID
#export TEMP=$PLEXOS_TEMP
#mkdir -p $PLEXOS_TEMP
 ```

5. Cut out one week to run DAY_AHEAD model on

 ```bash
python get_week.py
```

6. Run PLEXOS

  ```bash
mono $PLEXOS/PLEXOS64.exe -n "one_week_model.xml" -m DAY_AHEAD
```
