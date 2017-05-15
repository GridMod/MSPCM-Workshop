# plexos-hpc-walkthrough
Introduction for new users to run Plexos on the HPC

##[Obtain an account for NREL HPC](Obtain-Account.md)

##[Install git and bash on your laptop](INSTALL-GIT-BASH.md)

##[Login into NREL HPC, peregrine](Login-HPC.md)

##[View software and initiate a session on a compute node](Initial-Session.md)

##[First Time Setup of PLEXOS on HPC](Setup-PLEXOS.md)

##[Run a week of the Base Case](Run-PLEXOS.md)

##[Run Magma on that week](Run-Magma.md)

run coad to extract a week
Run RTC-GMLC

Install coad in /nopt/nrel/apps/coad/2.0
Install module for coad
Include how to install coad into a conda environment in the help of the module.

Assume Submit a job
Assume Monitor a job
Require git-bash for windows

cd /scratch/$USER

clone github.nrel.gov/aces/plexos-intro
Cd plexos-intro
Git clone https://github.com/GridMod/RTS-GMLC

qsub –q debug –I #get a single node from the reservation to run interactively.

source env/env-?.sh to set up environment
cp submit-template.sh submit.sh RTS-GMLC

cd RTS-GMLC
cp RTS_Data/FormattedData/PLEXOS/RTS-GMLC.xml .

Use coad to list models.
Use coad to add a new model which is for a week in July.

check submit.sh that model created is referenced.
setup and test license?
Run plexos on that week.

