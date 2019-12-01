# All-Splitting EPC Script
Electron-Phonon Coupling (EPC) calculation in Quantum Espresso (QE) program with q-mesh and irreducible representation splitting. 
1. The script will create mulitiple jobs calculating phonon and submit them to the remote cluster. 
2. After the phonon jobs are done, the script will collect the output files, create  and submit another set of jobs to calculate the EPC paramaters at each q-points.


## Toturial
Follow the following steps to do an all-splitting EPC calculation.
(If you need any information knowledge of EPC with [Quantum Espresso](https://www.quantum-espresso.org/), tutorials and examples can be found at [this](https://github.com/QEF/q-e) link.)
1. Before performing an all-splitting EPC calculation, one should prepare the following files:
   a. Temperatory files from a pre-converged scf run, i.e. the ```outdir```;
   b. ```prefix.a2fsave``` file;
   c. The ```epc_all_grid.sh``` script.
3. Edit the configuration section in the script:
   - ```CMD_SUBMIT``` command to submit the job to the remote cluster```;
   - ```CMD_LD_ESPRESSO``` command to load QE module thus your system can find QE exectuables;
   - ```PREFIX``` prefix for the QE calculations;
   - ```DIR_SCF``` the directory contains the scf temperatory files, also the ```prefix.a2fsave``` file should be copied to this directory;
   - ```DIR_PHONON``` temperatory directory will contain all phonon and EPC files;
   - ```NQ1; NQ2; NQ3``` equal to ```nq1; nq2; nq3``` in QE;
   - ```FIL_DYN``` equals to ```fildyn``` in QE;
   - ```FIL_DVSCF``` equals to ```fildvscvf``` in QE.
4. Initial the dynamic patterns, run:
```epc_all_grid.sh init```
This will copy the scf files to ```DIR_PHONON``` and do initialization. In ```dyn0``` file you will see how many q-points are there.
5. Edit the ```FIRST_Q; LAST_Q``` in the script. E.g. if you want to calculate only one q-points, say Gamma point, use ```FIRST_Q=1; LAST_Q=1```.
6. Edit the ```QE template``` and ```SLURM template``` in the script to fit your needs.
7. Do grid phonon calculation, run:
```epc_all_grid.sh grid```
8. Wait until all phonon jobs are finished.
9. Do EPC calculation, run:
```epc_all_grid.sh elph```
   

## Script Information
1. Operating System Platform: Linux
2. Dependency: BASH, Quantume Espresso (6.2.1)
3. SLURM Job System: Center for Computational Research (CCR) at UB is using SLURM to manage the queue. You may follow [this](https://ubccr.freshdesk.com/support/solutions/articles/5000686927-batch-computing-slurm-workload-manager-) post to translate it into your system.


## Author
Xiaoyu Wang (xwang224@buffalo.edu)

Department of Wizardary and Alchemical Engineering, State University of New York at Buffalo (UB)

