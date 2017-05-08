# RTS-GMLC Example Workflow

1. Copy the dataset into this folder
 ```
 cp ../../RTS-GMLC-Dataset/RTS-GMLC.xml .
 ```

2. Create a symbolic link to the timeseries datafiles
 ```
 ln -s ../../RTs-G ls -s ../../RTs-GMLC-Dataset/timeseries_data_files timeseries_data_files
 ```

3. 
 ```
 module purge
 module use /nopt/nrel/apps/modules/candidate/modulefiles
 #For PLEXOS 7.4
 module load epel gcc mono/4.6.2.7 xpressmp/8.0.4 plexos/7.400.2
 ```

4. 
 ```
#MAX_TEMP_FILE_AGE is an environmental variable that Plexos uses to determine how 
#old a temporary directory can be (in days) before it should be purged
#see http://wiki.energyexemplar.com/index.php?n=Article.AdvancedSettings
export MAX_TEMP_FILE_AGE=50

#PLEXOS_TEMP isan environmental variable that Plexos uses to store temporary files.
#Plexos creates subdirectories in this directory for each run.
#If the subdirectory gets deleted during the run then the run will fail when it tries to write the solution file.
export PLEXOS_TEMP=/scratch/$USER/tmp/$PBS_JOBID
export TEMP=$PLEXOS_TEMP
#make sure the PLEXOS_TEMP and TEMP directories exist
mkdir -p $PLEXOS_TEMP $TEMP
```

5.
```
mono $PLEXOS/PLEXOS64.exe -n "RTS-GMLC.xml" -m DAY_AHEAD
```
