# Steps to developing a script for hpc using breezy_hpc.r script

## Local

### Interactive

#### Sequential execution

Run inside rstudio

#### Parallel execution (doMC)

Run inside rstudio

### Local script

#### Sequential execution

```bash
hpc_script.r -t
```

#### Parallel execution (uses doMC)

```bash
hpc_script.r -p mc -c 6 -t
```

## HPC

Upload relevant project files

```bash
wdx="~/projects/coolproject/analysis"

cd $wd

ssh grace "mkdir -p $wdx" #make sure to use double not single quotes!
scp -r ctfs grace:$wdx
```

Connect to hpc
```bash
ssh grace
```

### Interactive environment

```bash
srun --pty -p interactive -n 4 bash #request four tasks in the interactive queue

wd=~/projects/ms3/analysis/full_workflow_poc
src=~/projects/ms3/src

cd $wd

module load miniconda
source activate parallelR3
```

#### Sequential execution

```bash
Rscript --vanilla $src/hpc_script.r out.csv -t
```

#### Parallel execution

```bash
mpirun -n 4 R --slave -f $src/hpc_script.r --args out.csv -p mpi -m logs -t
```

### Scavenge queue

#### Parallel execution

Set up slurm script (hpc_script_sbatch.sh)

```bash
#!/bin/bash

#SBATCH --mail-user=ben.s.carlson@gmail.com
#SBATCH --mem-per-cpu=5G
#SBATCH --error=poc_hpc_sqlite_simple.log
#SBATCH --output=poc_hpc_sqlite_simple.log

module load miniconda
source activate parallelR3

mpirun -n $n Rscript --vanilla $src/poc/ctmm/poc_hpc_sqlite_simple.r $out -p mpi -m $logs
```

Run using slurm

```bash
wd=~/projects/ms3/analysis/full_workflow_poc/test3

#need these for all scripts
export src=~/projects/ms3/src
export outp=out5
export out=$outp/out.csv
export logs=$outp/mpilogs

#slurm variables
export n=4
export t=10:00
export p=scavenge
export J=out5
export mail=NONE

#Make sure to make the output directory or mpi will fail because mpi log files go here
cd $wd
mkdir -p $outp

# These have to start with the --option b/c echo won't print - as first character
pars=`echo --ntasks $n -p $p -t $t -J $J --mail-type $mail`
exp=`echo --export=ALL,n=$n,p=$p,t=$t,J=$J,mail=$mail`

sbatch $pars $exp $src/poc/ctmm/poc_hpc_sqlite_simple_sbatch.sh
```

### Full run in day queue