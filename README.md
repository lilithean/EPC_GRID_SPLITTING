# All-Splitting EPC Script
Electron-Phonon Coupling (EPC) calculation in Quantum Espresso (QE) program with q-mesh and irreducible representation splitted. 
1. The script will create (and submit to remote cluster) a set of jobs to calculate phonon. 
2. After the phonon jobs are done, the script will collect the output files, create and submit another set of jobs to calculate the EPC paramaters at each q-points.


## Toturial
Follow the following steps to do an all-splitting EPC calculation.
(If you need any information of EPC with [Quantum Espresso](https://www.quantum-espresso.org/), tutorials and examples can be found at [this](https://github.com/QEF/q-e) link.)
1. Before performing an all-splitting EPC calculation, one should prepare the following files:
   - Temperatory files from a pre-converged scf run, i.e. the ```outdir``` in QE
   - ```prefix.a2fsave``` file from QE
   - The ```epc_all_grid.sh``` script
2. Edit the configuration section in the script:
   - ```CMD_SUBMIT``` command to submit jobs to the remote cluster, e.g. ```sbatch```
   - ```CMD_LD_ESPRESSO``` command to make sure your system can find QE exectuables, e.g. ```module load espresso/6.2.1```
   - ```PREFIX``` prefix for the QE calculations
   - ```DIR_SCF``` the directory contains the scf temperatory files, also the ```prefix.a2fsave``` file should be copied to this directory
   - ```DIR_PHONON``` temperatory directory will contain all phonon and EPC files
   - ```NQ1; NQ2; NQ3``` equal to ```nq1, nq2, nq3``` in QE
   - ```FIL_DYN``` equals to ```fildyn``` in QE
   - ```FIL_DVSCF``` equals to ```fildvscvf``` in QE

**remember, no space between the variables and the "equal signs" in bash:**
```
DIR_PHONON=/gpfs/scratch/qe_output      # this is good
DIR_PHONON =/gpfs/scratch/qe_output     # this is bad
DIR_PHONON= /gpfs/scratch/qe_output     # this is also bad
```

3. Initial the dynamic patterns, run:
```epc_all_grid.sh init```
This will copy the scf files to ```DIR_PHONON``` and do initialization. In ```dyn0``` file you will see how many q-points are there.
4. Edit the ```FIRST_Q; LAST_Q``` in the script. E.g. if you want to calculate only one q-points, say Gamma point, use ```FIRST_Q=1; LAST_Q=1```.
5. Edit the ```QE template``` and ```SLURM template``` in the script to fit your needs.
6. Do grid phonon calculation, run:
```epc_all_grid.sh grid```
7. Wait until all phonon jobs are finished.
8. Do EPC calculation, run:
```epc_all_grid.sh elph```
   

## Script Information
1. Operating System Platform: Linux
2. Dependency: BASH, Quantume Espresso (6.2.1)
3. SLURM Job System: Center for Computational Research (CCR) at UB is using SLURM to manage the queue. You may follow [this](https://ubccr.freshdesk.com/support/solutions/articles/5000686927-batch-computing-slurm-workload-manager-) post to translate it into your system.


## Author
Xiaoyu Wang (xwang224@buffalo.edu)

Department of Wizardary and Alchemical Engineering, State University of New York at Buffalo (UB)

