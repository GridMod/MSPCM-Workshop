#!/bin/bash

#example input to run the "Base" model in the WECC.xml input file in p partitions wiht o overlap days
# ./submitPLEXOS_split_execution.sh WECC.xml Base
# Note - I have not tried to run this file since it has been copied over to this repository. 
# No promises on all modules being correct and up to date or scripts working 

############################ USER MODIFIED SECTION ########################
export p=052 #partitions
export o=002 #overlap days
export feature="nodes=1,walltime=15:00"
export alloc="PLEXOSMODEL"
export queue="batch"
export runscript="runPLEXOS_7420.sh"
##########################################################################

#database name from first input parameter
name="${1%.*}"
#model name from second input parameter
model=$2

echo $name
#make a directory with same name as database
mkdir -p ${name}

#load some stuff
module purge
module load openmpi-epel python/3.3.3
module use /projects/PLEXOSMODEL/hpc-plexos/opt/modulefiles
module load plexos-tools/0.2.0
#module load coad/master mono/3.2.1 phelper/master plexos/6.301.1 parser/0.3.4 xpressmp/7.6

#save directory executing this file from
rootdir=$(pwd)
cd $rootdir

echo "splitmodel.py -n $name.xml -m $model -p $p -o $o"
#setsolverdefaults.py -n OLd$i/RMPP_Core_DB_Storage_6208.xml -m $1 -s CPLEX
#execute splitmodel script from the phelper module
#run splitmodel.py -h to get help on this function
splitmodel.py -n $name.xml -m $model -p $p -o $o

#for every partition, do:
for I in $(seq 001 $p); do
 #string of partition number i.e. '001'
 i=$(printf "%03d" $I)
 #make directory
 mkdir -p ${name}/${model}_${p}P_OLd${o}_$i
 #copy scripts and databases into directory
 cp "${runscript}" "${name}/${model}_${p}P_OLd${o}_$i/."
 cp "${name}.xml" "${name}/${model}_${p}P_OLd${o}_$i/."
 #create links to datafiles (not actually copied)
 ln -s "${rootdir}/Data Files/" "${name}/${model}_${p}P_OLd${o}_$i/."
 #go to directory
 cd "${name}/${model}_${p}P_OLd${o}_$i/"
 pwd
 #set the root directory for the to-be-submitted job
 PBS_O_WORKDIR=$(pwd)
 echo "qsub -A ${alloc} -q ${queue}  -l ${feature} -v filename="${name}",model="${model}_${p}P_OLd${o}_$i" ${runscript}"
 #submit job to HPC scheduler
 qsub -A ${alloc} -q ${queue}  -l ${feature} -v filename="${name}",model="${model}_${p}P_OLd${o}_$i" ${runscript}
 #go back to root directory and start over
 cd $rootdir
done
