#!/bin/bash

#example input to run the models listed in models.txt in the WECC.xml input file
# ./submitPLEXOS_list.sh RTS-GMLC.xml DAY_AHEAD

############################ USER MODIFIED SECTION ########################
export feature="nodes=1,walltime=8:00:00"
export alloc="PLEXOSMODEL"    #allcoation to use
export queue="batch-h"          #hpc queue
export runscript="runPLEXOS_73030303030303030303030303030303030303030303030303030303030300.sh"
##########################################################################

name="${1%.*}"
models=$2

echo $models
mkdir -p ${models}

rootdir=$(pwd)
cd $rootdir

cp "${runscript}" "${models}/."
cp run_html_output_rts_DA.R "${models}/."
cp gen_name_mapping_WECC_RTS.csv "${models}/."
cp input_data_rts.csv "${models}/."
cp "${name}.xml" "${models}/."
 #ln -s "${rootdir}/Data Files/" "${name}/$line/."
ln -s "${rootdir}/timeseries_data_files/" "${models}"
cd "${models}/"

sed -i "s/solution_folder/Model\ "${models}"\ Solution/g" run_html_output_rts_DA.R  

pwd
PBS_O_WORKDIR=$(pwd)
submitcommand="qsub -q ${queue} -A ${alloc}  -l ${feature} -v filename="${name}",model="${models}" ${runscript}"
echo $submitcommand
$submitcommand
cd $rootdir

