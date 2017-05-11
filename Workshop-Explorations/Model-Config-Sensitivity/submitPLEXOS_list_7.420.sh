#!/bin/bash

#example input to run the models listed in models.txt in the WECC.xml input file
# ./submitPLEXOS_list.sh WECC.xml models.txt

############################ USER MODIFIED SECTION ########################
export feature="nodes=1,walltime=5:00:00"
export alloc="PLEXOSMODEL"    #allcoation to use
export queue="batch"          #hpc queue
export runscript="runPLEXOS_7420.sh"
##########################################################################

name="${1%.*}"
models=$2

echo $name
mkdir -p ${name}

rootdir=$(pwd)
cd $rootdir

while read line; do
 mkdir -p ${name}/${line}
 cp runPLEXOS_7420.sh "${name}/${line}/."
 cp rplexos_parser.R "${name}/${line}/."
 cp "${name}.xml" "${name}/${line}/."
 #ln -s "${rootdir}/Data Files/" "${name}/$line/."
 ln -s "${rootdir}/timeseries_data_files/" "${name}/$line/."
 cd "${name}/${line}/"
 pwd
 PBS_O_WORKDIR=$(pwd)
 submitcommand="qsub -q ${queue} -A ${alloc}  -l ${feature} -v filename="${name}",model="${line}" ${runscript}"
 echo $submitcommand
 $submitcommand
 cd $rootdir
done < $models
