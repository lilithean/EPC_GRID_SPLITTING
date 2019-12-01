#!/usr/bin/env bash
#===============================================================================
#
#        FILE: eph_grid.sh
#
#       USAGE: eph_grid.sh [task]
#
# DESCRIPTION: Parallel Quantum Espresso jobs in Q-grid and irreducible 
#              representations. A pre-converged scf run should be provided.
# 
#      AUTHOR: Xiaoyu Wang, xwang224@buffalo.edu
#     COMPANY: Univ. Buffalo, Dept. Chem.
#     VERSION: 2.1
#     CREATED: 02.07.2019 - 22:57:00
#    REVISION: 11.13.2019
#===============================================================================
set -eu -o pipefail

#-------------------------------------------------------------------------------
#  Configurations 
#-------------------------------------------------------------------------------
CMD_SUBMIT='sbatch'
CMD_LD_ESPRESSO='module load espresso/6.2.1'

PREFIX='rbs'
DIR_SCF='/projects/academic/ezurek/xiaoyu/miao/30GPa/test_qpts/scf'
DIR_PHONON='/gpfs/scratch/xwang224/qe/rbs30/3'

NQ1=3; NQ2=3; NQ3=3
FIL_DYN='dyn'
FIL_DVSCF='dvscf'

FIRST_Q=1; LAST_Q=4


usage() {
  printf "\n"
  printf "Parallel Quantum Espresso jobs in Q-grid and irreducible\n"
  printf "representations. A pre-converged scf run should be provided.\n"
  printf "\n"
  printf "usage: ${0} [task]\n"
  printf "tasks:\n"
  printf "    'init' initial phonon grid calculation from an scf directory\n"
  printf "    'grid' submit parallelized phonon jobs\n"
  printf "    'elph' calculate el-ph coupling\n"
}

err() {
  printf "Error in ${FUNCNAME[1]} $(date +'%Y-%m-%d %H:%M:%S'): $@" >&2
}

msg() {
  printf "$(date +'%Y-%m-%d %H:%M:%S'): $@" >&1
}

[[ "${#}" == 0 ]] && {
  err "no options given: %s\n" ${OPTIND}
  usage
  exit 1
}

#while [ $1 != "" ]; 

#-------------------------------------------------------------------------------
#  Task dyninit
#-------------------------------------------------------------------------------
if [ ${1} == 'init' ]; then
echo
echo PHONON GRID INITIALIZATION
echo 

if ! [ -d ${DIR_SCF} ]; then
echo
err "scf directory not exists"
echo 
fi

if ! [ ${DIR_SCF} == ${DIR_PHONON} ]; then
echo
echo COPYTING SCF DIRECTORY TO PHONON DIRECTORY
echo 
if [ -d ${DIR_PHONON} ]; then
rm -rf ${DIR_PHONON}
fi
cp -rf ${DIR_SCF} ${DIR_PHONON}
fi

# QE template
cat > ph0.inp << EOF
initial_dynmat
&inputph
       prefix = '${PREFIX}',
       outdir = '${DIR_PHONON}',
     fildvscf = '${FIL_DVSCF}',
       fildyn = '${FIL_DYN}',
        ldisp = .true.,
          nq1 = ${NQ1}, 
          nq2 = ${NQ2}, 
          nq3 = ${NQ3},
    start_irr = 0, 
     last_irr = 0,
       tr2_ph = 1.0d-16,
    alpha_mix = 0.2,
 /
EOF

echo
echo INITIALIZE PHONON GRID
echo 
${CMD_LD_ESPRESSO}
ph.x < ph0.inp > ph0.out

echo
echo GRID INITIALIZATION DONE

exit 0

fi



#-------------------------------------------------------------------------------
#  Task gridphon
#-------------------------------------------------------------------------------
if [ ${1} == 'grid' ]; then
echo
echo PHONON GRID CALCULATION
echo 

if ! [ -d finished_job ]; then
mkdir finished_job
fi

N_Q=$(sed '2q;d' ${FIL_DYN}0)
echo
echo NUMBER OF Q-POINTS IS ${N_Q}
echo

if [ ${LAST_Q} -gt ${N_Q} ]; then
LAST_Q=${N_Q}
fi

for q in `seq ${FIRST_Q} ${LAST_Q}`; do
N_IRR=$(grep -B 1 '</NUMBER_IRR_REP>' ${DIR_PHONON}/_ph0/${PREFIX}.phsave/patterns.${q}.xml | head -1)

for irr in `seq 1 ${N_IRR}`; do
echo WORKING ON Q-POINT ${q} IRREP ${irr}

#QE template
cat > ph${q}.${irr}.inp << EOF
grid_phon
&inputph
       tr2_ph = 1.0d-16,
    alpha_mix = 0.2,
       prefix = '${PREFIX}',
       outdir = '${DIR_PHONON}/${q}.${irr}',
     fildvscf = '${FIL_DVSCF}',
       fildyn = '${FIL_DYN}',
        ldisp = .true.,
        trans = .true.,
      !recover = .true.,
          nq1 = ${NQ1}, 
          nq2 = ${NQ2}, 
          nq3 = ${NQ3},
      start_q = ${q}, 
       last_q = ${q},
    start_irr = ${irr}, 
     last_irr = ${irr},
 /
EOF

#SLURM template
cat > ph${q}.${irr}.slurm << EOF
#!/bin/sh
#SBATCH --job-name=ph${q}.${irr} --output=ph${q}.${irr}.out
#SBATCH --nodes=1 --tasks-per-node=32 --mem=187000 --time=72:00:00
#SBATCH --cluster=ub-hpc --partition=skylake --qos=skylake --account=ezurek 
##SBATCH --constraint=CPU-Gold-6130

ulimit -s unlimited
export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi.so

echo
echo LOADING QUANTUM ESPRESSO PROGRAM
echo 
module purge
${CMD_LD_ESPRESSO}

echo
echo CREATING TEMPORARY DIRECTORY
echo 
rm -rf ${DIR_PHONON}/${q}.${irr}
mkdir -p ${DIR_PHONON}/${q}.${irr}/_ph0/${PREFIX}.phsave/
cp -r ${DIR_PHONON}/${PREFIX}.* ${DIR_PHONON}/${q}.${irr}
cp -r ${DIR_PHONON}/_ph0/${PREFIX}.phsave/* ${DIR_PHONON}/${q}.${irr}/_ph0/${PREFIX}.phsave/

echo
echo RUNNING PHONON JOB
echo 

srun -n \$SLURM_NPROCS ph.x -ni 1 -nk 8 -input ph${q}.${irr}.inp

echo
echo CLEANING TEMPORARY DIRECTORY
echo 
find ${DIR_PHONON}/${q}.${irr}/ -name "*wfc*" -delete

mv ph${q}.${irr}.* finished_job

EOF

${CMD_SUBMIT} ph${q}.${irr}.slurm | grep "Submitted" & 

done  # close irrep
done  # close q

wait

msg "all done\n"

exit 0
fi

#-------------------------------------------------------------------------------
#  Task elph
#-------------------------------------------------------------------------------
if [ ${1} == 'elph' ]; then
echo
echo GRID RESULTS COLLECTION
echo 

N_Q=$(sed '2q;d' ${FIL_DYN}0)
echo
echo NUMBER OF Q-POINTS IS ${N_Q}
echo

if [ ${LAST_Q} -ge ${N_Q} ]; then
LAST_Q=${N_Q}
fi

for q in `seq ${FIRST_Q} ${LAST_Q}`; do
echo
echo CREATING TEMPORARY DIRECTORY FOR Q ${q}
echo
rm -rf ${DIR_PHONON}/${q}
mkdir -p ${DIR_PHONON}/${q}/_ph0/${PREFIX}.phsave/
cp -r ${DIR_PHONON}/${PREFIX}.save/ ${DIR_PHONON}/${q}
cp -r ${DIR_PHONON}/${PREFIX}.a2Fsave ${DIR_PHONON}/${q}
cp -r ${DIR_PHONON}/_ph0/${PREFIX}.phsave/* ${DIR_PHONON}/${q}/_ph0/${PREFIX}.phsave/

N_IRR=$(grep -B 1 '</NUMBER_IRR_REP>' ${DIR_PHONON}/_ph0/${PREFIX}.phsave/patterns.${q}.xml | head -1)
PAT_MODES=($(grep -B 1 '</NUMBER_OF_PERTURBATIONS>' ${DIR_PHONON}/_ph0/${PREFIX}.phsave/patterns.${q}.xml | sed 's/[^0-9]*//g'))


if ! [ ${q} == 1 ]; then
mkdir -p ${DIR_PHONON}/${q}/_ph0/${PREFIX}.q_${q}/
cp -r ${DIR_PHONON}/${q}.1/_ph0/${PREFIX}.q_${q}/${PREFIX}.save/ ${DIR_PHONON}/${q}/_ph0/${PREFIX}.q_${q}/
cp -r ${DIR_PHONON}/${q}.1/_ph0/${PREFIX}.q_${q}/${PREFIX}.xml ${DIR_PHONON}/${q}/_ph0/${PREFIX}.q_${q}/
#cp -r ${DIR_PHONON}/${q}.1/_ph0/${PREFIX}.q_${q}/${PREFIX}.wfc* ${DIR_PHONON}/${q}/_ph0/${PREFIX}.q_${q}/

SZ_DVSCF=$(($(wc -c < ${DIR_PHONON}/${q}.1/_ph0/${PREFIX}.q_${q}/${PREFIX}.dvscf1)/${PAT_MODES[0]}))
SZ_DVSCF_PAW=$(($(wc -c < ${DIR_PHONON}/${q}.1/_ph0/${PREFIX}.q_${q}/${PREFIX}.dvscf_paw1)/${PAT_MODES[0]}))
LST_DVSCF_PAW=$(ls ${DIR_PHONON}/${q}.1/_ph0/${PREFIX}.q_${q}/ | grep "dvscf_paw")

else

SZ_DVSCF=$(($(wc -c < ${DIR_PHONON}/${q}.1/_ph0/${PREFIX}.dvscf1)/${PAT_MODES[0]}))
SZ_DVSCF_PAW=$(($(wc -c < ${DIR_PHONON}/${q}.1/_ph0/${PREFIX}.dvscf_paw1)/${PAT_MODES[0]}))
LST_DVSCF_PAW=$(ls ${DIR_PHONON}/${q}.1/_ph0/ | grep "dvscf_paw")
fi

mode=0

for irr in `seq 1 ${N_IRR}`; do
echo WORKING ON Q-POINT ${q} IRREP ${irr}
echo $SZ_DVSCF
echo $SZ_DVSCF_PAW

cp -f ${DIR_PHONON}/${q}.${irr}/_ph0/${PREFIX}.phsave/dynmat.${q}.${irr}.xml ${DIR_PHONON}/${q}/_ph0/${PREFIX}.phsave


if [ ${q} == 1 ]; then
dd bs=${SZ_DVSCF} count=${PAT_MODES[irr-1]} skip=${mode} seek=${mode} if=${DIR_PHONON}/${q}.${irr}/_ph0/${PREFIX}.dvscf1 of=${DIR_PHONON}/${q}/_ph0/${PREFIX}.dvscf1 status=none

for dvscf_paw in ${LST_DVSCF_PAW}; do
dd bs=${SZ_DVSCF_PAW} count=${PAT_MODES[irr-1]} skip=${mode} seek=${mode} if=${DIR_PHONON}/${q}.${irr}/_ph0/${dvscf_paw} of=${DIR_PHONON}/${q}/_ph0/${dvscf_paw} status=none
done # close dvscf_paw

else

dd bs=${SZ_DVSCF} count=${PAT_MODES[irr-1]} skip=${mode} seek=${mode} if=${DIR_PHONON}/${q}.${irr}/_ph0/${PREFIX}.q_${q}/${PREFIX}.dvscf1 of=${DIR_PHONON}/${q}/_ph0/${PREFIX}.q_${q}/${PREFIX}.dvscf1 status=none

for dvscf_paw in ${LST_DVSCF_PAW}; do
dd bs=${SZ_DVSCF_PAW} count=${PAT_MODES[irr-1]} skip=${mode} seek=${mode} if=${DIR_PHONON}/${q}.${irr}/_ph0/${PREFIX}.q_${q}/${dvscf_paw} of=${DIR_PHONON}/${q}/_ph0/${PREFIX}.q_${q}/${dvscf_paw} status=none
done # close dvscf_paw

fi

mode=$((mode+PAT_MODES[irr-1]))

done # close irr

cp -f ${DIR_PHONON}/${q}.1/_ph0/${PREFIX}.phsave/dynmat.${q}.0.xml ${DIR_PHONON}/${q}/_ph0/${PREFIX}.phsave

# QE template
cat > ph${q}.inp << EOF
grid_phon
&inputph
             tr2_ph = 1.0d-16,
          alpha_mix = 0.2,
             prefix = '${PREFIX}',
             outdir = '${DIR_PHONON}/${q}',
           fildvscf = '${FIL_DVSCF}',
             fildyn = '${FIL_DYN}',
              ldisp = .true.,
              trans = .true.,
            recover = .true.,
                nq1 = ${NQ1}, 
                nq2 = ${NQ2}, 
                nq3 = ${NQ3},
            start_q = ${q}, 
             last_q = ${q},
 /
EOF

# QE template
cat > elph${q}.inp << EOF
grid_elph
&inputph
             tr2_ph = 1.0d-16,
          alpha_mix = 0.2,
             prefix = '${PREFIX}',
             outdir = '${DIR_PHONON}/${q}',
           fildvscf = '${FIL_DVSCF}',
             fildyn = '${FIL_DYN}',
              ldisp = .true.,
              trans = .false.,
                nq1 = ${NQ1}, 
                nq2 = ${NQ2}, 
                nq3 = ${NQ3},
            start_q = ${q}, 
             last_q = ${q},
    electron_phonon = 'interpolated',
        el_ph_sigma = 0.005,
       el_ph_nsigma = 10,
 /
EOF

# SLURM template
cat > elph${q}.slurm << EOF
#!/bin/sh
#SBATCH --job-name=elph${q} --output=elph${q}.out
#SBATCH --nodes=1 --tasks-per-node=32 --mem=187000 --time=72:00:00
#SBATCH --cluster=ub-hpc --partition=largemem --qos=largemem --account=ezurek 
#SBATCH --constraint=CPU-Gold-6130

ulimit -s unlimited
export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi.so

echo
echo LOADING QUANTUM ESPRESSO PROGRAM
echo 
module purge
${CMD_LD_ESPRESSO}


echo
echo RUNNING PHONON JOB
echo 

srun -n \$SLURM_NPROCS ph.x -ni 1 -nk 8 -input ph${q}.inp
srun -n \$SLURM_NPROCS ph.x -ni 1 -nk 8 -input elph${q}.inp

#echo
#echo CLEANING TEMPORARY DIRECTORY
#echo 
#rm -rf ${DIR_PHONON}/${q}

mv elph${q}.* finished_job
mv ph${q}.inp finished_job


EOF

${CMD_SUBMIT} elph${q}.slurm | grep "Submitted"  

done # close q

echo
echo GRID COLLECTION DONE

exit 0
fi


#-------------------------------------------------------------------------------
#  Fin.
#-------------------------------------------------------------------------------
