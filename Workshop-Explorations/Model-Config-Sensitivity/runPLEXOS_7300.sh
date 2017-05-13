#! /bin/bash

cd $PBS_O_WORKDIR
echo 'I am in ' $PBS_O_WORKDIR

module purge
module use /nopt/nrel/apps/modules/candidate/modulefiles
#For PLEXOS 7.3
module load epel gcc mono/4.6.2.7 xpressmp/7.8.0 plexos/7.300.3
module load R/3.2.2

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

## Run DA Model
plexos_command="mono $PLEXOS/PLEXOS64.exe -n "${filename}.xml" -m "${model}""
echo $plexos_command
$plexos_command

## Run RT Model
ln -s "../${model}/Model ${model} Solution/." "Model ${model} Solution"
plexos_command="mono $PLEXOS/PLEXOS64.exe -n "${filename}.xml" -m "${model}_RT""
echo $plexos_command
$plexos_command
sed -i "s/solution_rt_folder/Model\ "${model}_RT"\ Solution/g" run_html_output_rts_DA_RT.R  

## Create Rplexos db
solution_zip=$(ls $PBS_O_WORKDIR/$filename/$model/*Solution/*zip)
echo Solution = $solution_zip
#Rscript rplexos_parser.R
ssh login1 "cd $PWD; ./run_magma_ssh.sh"

## Move Rplexos parsed database into the parent directory
#mv "Model ${model} Solution-rplexos.db" $PBS_O_WORKDIR/..
