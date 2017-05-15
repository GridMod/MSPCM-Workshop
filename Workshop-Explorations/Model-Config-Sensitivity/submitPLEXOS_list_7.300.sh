#!/bin/bash

#example input to run the models listed in models.txt in the WECC.xml input file
# ./submitPLEXOS_list.sh WECC.xml models.txt

############################ USER MODIFIED SECTION ########################
export feature="nodes=1,walltime=8:00:00"
export alloc="PLEXOSMODEL"    #allcoation to use
export queue="batch"          #hpc queue
export runscript="runPLEXOS_7300.sh"
##########################################################################

name="${1%.*}"
models=$2

echo $name
mkdir -p ${name}

rootdir=$(pwd)
cd $rootdir

while read line; do
 mkdir -p ${name}/${line}
 cp "${runscript}" "${name}/${line}/."
 cp run_html_output_rts_DA.R "${name}/${line}/."
 cp run_html_output_rts_DA_RT.R "${name}/${line}/."
 cp gen_name_mapping_WECC_RTS.csv "${name}/${line}/."
 cp input_data_rts.csv "${name}/${line}/."
 cp run_magma_ssh.sh "${name}/${line}/."
 cp "${name}.xml" "${name}/${line}/."
 #ln -s "${rootdir}/Data Files/" "${name}/$line/."
 ln -s "${rootdir}/timeseries_data_files/" "${name}/$line/."
 cd "${name}/${line}/"
 sed -i "s/solution_folder/Model\ "${line}"\ Solution/g" run_html_output_rts_DA.R  
 sed -i "s/solution_folder/Model\ "${line}"\ Solution/g" run_html_output_rts_DA_RT.R  
 pwd
 PBS_O_WORKDIR=$(pwd)
 submitcommand="qsub -q ${queue} -A ${alloc}  -l ${feature} -v filename="${name}",model="${line}" ${runscript}"
 echo $submitcommand
 $submitcommand
 cd $rootdir
done < $models
