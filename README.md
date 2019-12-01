# All-Splitting EPC Script
Electron-Phonon Coupling (EPC) calculation in Quantum Espresso (QE) program with q-mesh and irreducible representation splitting. 
1. The script will create mulitiple jobs calculating phonon and submit them to the remote cluster. 
2. After the phonon jobs are done, the script will collect the output files, create  and submit another set of jobs to calculate the EPC paramaters at each q-points.


## Getting Started
1. First you need basic knowledge of doing EPC with [Quantum Espresso](https://www.quantum-espresso.org/). Tutorials and examples can be found at [this](https://github.com/QEF/q-e) link.
2. Before performing an all-splitting EPC, one should prepare the following files:
   a. Output files from a pre-converged scf run.
   b. A prefix.a2fsave file
   c. The All-Splitting EPC script
3. Edit the configurations section:
   - ```CMD_SUBMIT      # command to submit the job to the remote cluster```
   - ```CMD_LD_ESPRESSO # command to load QE module thus your system can find QE exectuables.```
   
   
Xiaoyu Wang (xwang224@buffalo.edu)
Department of Wizardary and Alchemical Engineering, State University of New York at Buffalo (UB)


Operating System: CentOS Linux 7
Dependency: BASH, Quantume Espresso (6.2.1)
SLURM Job System: Center for Computational Research (CCR) at UB is using SLURM to manage the queue. You may follow [this](https://ubccr.freshdesk.com/support/solutions/articles/5000686927-batch-computing-slurm-workload-manager-) post to translate it into your system.
