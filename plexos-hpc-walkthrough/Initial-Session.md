## Initial Session on Eagle

A [user basics page](https://www.nrel.gov/hpc/eagle-user-basics.html) is available on the [NREL HPC Website](https://hpc.nrel.gov)

Here we walk through an initial session on the HPC, going to the scratch filesystem, and obtaining an interactive session on a compute node, finding the plexos software.

```bash
[$USER@laptop ~]$ ssh el1.hpc.nrel.gov
[$USER@el1 ~]$ pwd
/home/$USER
```
On the HPC system we will work out of the scratch filesystem.  You can put files you want to keep for a long time in the home filesystem, but it is much smaller than the scratch filesystem and we will not want to run large compute and data intensive jobs from that filesystem.  The home filesystem is backed up nightly whereas scratch has untouched data deleted periodically.

```bash
[$USER@el1 ~]$ cd /scratch/$USER
[$USER@el1 $USER]$ pwd
/scratch/$USER
```

We will aquire an interactive session on a compute node to do our work and will request it from the batch scheduler using salloc.
```bash
[$USER@el1 $USER]$ salloc -N 1 -t 30 -A naris
salloc: Granted job allocation 541695
srun: Step created for job 541695
[$USER@r1i3n24 $USER]$ squeue -u $USER
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
            541695     short       sh    $USER  R       1:50      1 r1i3n24
[$USER@r1i3n24 $USER]$ pwd
/scratch/$USER
```
We landed in the scratch file system on the new host, r1i3n24, and can see that we have one job running using squeue.

'modules' is used to manage software that we have available to execute from the command line.  Here, we 
list our currently loaded software, 
purge our currently loaded software,
make available the plexos software, 
load the plexos software which depends on mono, centos and the xpressmp solvers.

```bash
[$USER@r1i3n24 $USER]$ module list
No modules loaded
[$USER@r1i3n24 $USER]$ module avail plexos

--------------------------------------------------------------------- /nopt/nrel/apps/modules/default/modulefiles ---------------------------------------------------------------------
   plexos/7.300.4    plexos/7.400.2 (D)

  Where:
   D:  Default Module

Use "module spider" to find all possible modules.
Use "module keyword key1 key2 ..." to search for all possible modules matching any of the "keys".


[$USER@r1i3n24 $USER]$ module load plexos/7.400.2
pLmod has detected the following error:  Cannot load module "plexos/7.400.2". At least one of these module(s) must be loaded:
   mono/4.6.2.7

While processing the following module(s):
    Module fullname  Module Filename
    ---------------  ---------------
    plexos/7.400.2   /nopt/nrel/apps/modules/default/modulefiles/plexos/7.400.2

[$USER@r1i3n24 $USER]$ module load mono/4.6.2.7
[$USER@r1i3n24 $USER]$ module load xpressmp/8.0.4
[$USER@r1i3n24 $USER]$ module load centos
[$USER@r1i3n24 $USER]$ module load plexos/7.400.2
[$USER@r1i3n24 $USER]$ module list

Currently Loaded Modules:
  1) mono/4.6.2.7   2) xpressmp/8.0.4   3) centos/7.4   4) plexos/7.400.2

 

```

## Initial Session on Peregrine

A [getting started guide](https://hpc.nrel.gov/users/systems/peregrine/getting-started-for-users-new-to-high-performance-computing) is available on the [NREL HPC Website](https://hpc.nrel.gov)

Here we walk through an initial session on the HPC, going to the scratch filesystem, and obtaining an interactive session on a compute node, finding the plexos software.

```bash
[wjones@login4 ~]$ pwd
/home/wjones
```
On the HPC system we will work out of the scratch filesystem.  You can put files you want to keep for a long time in the home filesystem, but it is much smaller than the scratch filesystem and we will not want to run large compute and data intensive jobs from that filesystem.

```bash
[wjones@login4 scratch]$ cd /scratch/$USER
[wjones@login4 wjones]$ pwd
/scratch/wjones
```

We will aquire an interactive session on a compute node to do our work and will request it from the batch scheduler using qsub.
```
[wjones@login4 wjones]$ qsub -I -A PLEXOSMODEL -l advres=workshop.57721,nodes=1,walltime=30:00 -q batch-h 
qsub: waiting for job 3211739 to start
qsub: job 3211739 ready

[wjones@n0289 wjones]$ qstat -u $USER

hpc-admin2.hpc.nrel.gov: 
                                                                                  Req'd       Req'd       Elap
Job ID                  Username    Queue    Jobname          SessID  NDS   TSK   Memory      Time    S   Time
----------------------- ----------- -------- ---------------- ------ ----- ------ --------- --------- - ---------
3211739                 wjones      debug    STDIN             60456     1      1       --   00:30:00 R  00:00:09
[wjones@n0289 wjones]$ pwd
/scratch/wjones
```
We landed in the scratch file system on the new host, n0289, and can see that we have one job running using qstat.

'modules' is used to manage software that we have available to execute from the command line.  Here, we 
list our currently loaded software, 
purge our currently loaded software,
make available the plexos software, 
load the plexos software which depends on mono and the xpressmp solvers.

```bash
[wjones@n0289 wjones]$ module list
Currently Loaded Modulefiles:
  1) comp-intel/13.1.3         2) impi-intel/4.1.1-13.1.3
[wjones@n0289 wjones]$ module use /nopt/nrel/apps/modules/candidate/modulefiles
[wjones@n0289 wjones]$ module avail plexos

------------------------------------------------ /nopt/nrel/apps/modules/candidate/modulefiles -------------------------------------------------
plexos/6.400.2 plexos/7.200.2 plexos/7.300.3 plexos/7.300.4 plexos/7.400.2
[wjones@n0289 wjones]$ module purge
[wjones@n0289 wjones]$ module load plexos/7.400.2
plexos/7.400.2(16):ERROR:151: Module 'plexos/7.400.2' depends on one of the module(s) 'mono/4.6.2.7'
plexos/7.400.2(16):ERROR:102: Tcl command execution failed: prereq mono/4.6.2.7

[wjones@n0289 wjones]$ module load mono/4.6.2.7
[wjones@n0289 wjones]$ module load xpressmp/8.0.4
[wjones@n0289 wjones]$ module load plexos/7.400.2
[wjones@n0289 wjones]$ module list
Currently Loaded Modulefiles:
  1) mono/4.6.2.7     2) xpressmp/8.0.4   3) plexos/7.400.2
```
