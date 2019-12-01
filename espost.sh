#!/bin/bash
#
#      Espresso Phonon Bash Script "esphresso.sh"
#      by Xiaoyu Wang (xwang224@buffalo.edu)
#
#
# & changelog
# ver 1.0.1 (2019 Feb 07 22:57): publish the 'alpha' 
# ver 1.0.2 (2019 Feb 07 23:15): parametrize lattice and atomic position; add TASK qscf
# ver 1.0.3 (2019 Feb 08 00:32): add TASK lambda
# ver 1.0.4 (2019 Feb 09 12:23): remove qscf; now lambda read q-points weight directly from elph output; switched to Bourne Again SHell (bash)
#
#
# & introduction
#
#   usage: ./esphresso.sh <task>
#
# tasks can be performed:
# - init
# - grid
#
# please go through the following configuration section below to personalize your qe jobs

if [ $# -eq 0 ]; then
# which job to run: default is scf
# other choices are: clean, veryclean, init, grid, elph, q2r, dos (not implemented), lambda
echo usage: $0 "[task]"
exit 0
fi

# CONFIG qe variable setting 
cmd_submit='sbatch'
prefix='12-172'
tmpdir='/gpfs/scratch/xwang224/qe_output/12-172/scf/'
pseudodir='./'
nq1='6'; nq2='6'; nq3='8'
mu='0.1'

# CONFIG file and bash job settings
fildyn='dyn'
fildvscf='dvscf'
filfc='fc'

# check if temp directory exists
if ! [ -d $tmpdir ]; then
mkdir -p $tmpdir
fi

# TASK q2r
if [ $1 = 'q2r' ]; then
echo 'q2r calc'

cat > q2r.inp << EOF
&input
  fildyn='$fildyn',
  zasr='crystal',
  flfrc='$filfc',
  la2f=.true.
/
EOF

module load espresso/6.2.1
q2r.x < q2r.inp > q2r.out

echo 'force field calculation done'

exit 0
fi


#TASK lambda
if [ $1 = 'lambda' ]; then
echo 'lambda calc'
n_q=$(sed '2q;d' ${fildyn}0)
readarray -t -n $n_q -s 2 qpts < ${fildyn}0
weight=($(grep 'nqs' q2r.out | awk '{print $2}'))

cat > lambda.inp << EOF
200  0.12  1
$n_q
$(paste <(printf "%s    \n" "${qpts[@]}") <(printf "%s\n" "${weight[@]}"))
$(seq 1 $n_q | awk '{printf "elph_dir/elph.inp_lambda.%i\n", $1}')
$mu
EOF

module load espresso/6.2.1
lambda.x < lambda.inp > lambda.out

echo 'lambda calculation done'

exit 0
fi

# END TASK LIST
echo 'Request task cannot be processed'
exit -1
