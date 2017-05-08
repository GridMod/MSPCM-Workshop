# RTS-GMLC Example Workflow

1. Copy the dataset into this folder
 ```
 cp ../../RTS-GMLC-Dataset/RTS-GMLC.xml .
 ```

2. Create a symbolic link to the timeseries datafiles
 ```
 ln -s ../../RTS-GMLC-Dataset/timeseries_data_files timeseries_data_files
 ```

3. Get yourself an interactive node
 ```
 qsub -I -A PLEXOSMODEL -q debug
 ```
 
4. Setup your environment
 ```
 module purge
 module use /nopt/nrel/apps/modules/candidate/modulefiles
 #For PLEXOS 7.4
 module load epel gcc mono/4.6.2.7 xpressmp/8.0.4 plexos/7.400.2
 ```

5.  Add the PLEXOS temp file
 ```
#PLEXOS_TEMP isan environmental variable that Plexos uses to store temporary files.
#Plexos creates subdirectories in this directory for each run.
#If the subdirectory gets deleted during the run then the run will fail when it tries to write the solution file.
export PLEXOS_TEMP=/scratch/$USER/tmp/$PBS_JOBID
export TEMP=$PLEXOS_TEMP
#make sure the PLEXOS_TEMP and TEMP directories exist
mkdir -p $PLEXOS_TEMP $TEMP
```

6. run PLEXOS
```
mono $PLEXOS/PLEXOS64.exe -n "RTS-GMLC.xml" -m DAY_AHEAD
```
