### machine specific settings ### 

# determine machine
if [ -z $MACH ]
then 
  case "`hostname -d | cut -d. -f1`" in 
  *fram*) MACH=fram ;; 
  *betzy*) MACH=betzy ;; 
  *) echo "Could not identify machine."
     echo "please set environmental variable \$MACH or specify script argument MACH=" 
     exit 1 ;;  
  esac
fi 

# apply machine settings
case $MACH in
fram) 
  MIN_NODES=4
  TASKS_PER_NODE=32
  : ${WORK:=/cluster/work/users/$USER} 
  : ${INPUTDATA:=/cluster/shared/noresm/inputdata}
  source /cluster/software/lmod/lmod/init/csh
  module purge --force 
  module load StdEnv
  module load NCO/4.7.7-intel-2018b
  module load intel/2018b
  module load netCDF/4.6.1-intel-2018b
  module load netCDF-Fortran/4.4.4-intel-2018b    
  ulimit -s unlimited
  ;; 
betzy)
  MIN_NODES=4
  TASKS_PER_NODE=128
  : ${WORK:=/cluster/work/users/$USER} 
  : ${INPUTDATA:=/cluster/shared/noresm/inputdata}
  : ${INPUTDATA_ASSIM:=/cluster/projects/nn9039k/inputdata}
  source /cluster/installations/lmod/lmod/init/sh
  module --quiet restore system
  module load StdEnv
  module load NCO/5.1.9-iomkl-2022a
  module load netCDF-Fortran/4.6.0-iompi-2022a
  module load iompi/2022a
  module load CMake/3.12.1
  export MKL_DEBUG_CPU_TYPE=5
  ulimit -s unlimited
  ;; 
*)
  echo "Unkown machine ${MACH}. Program will stop." 
  exit 1 ;;   
esac 
export MACH WORK INPUTDATA MIN_NODES TASKS_PER_NODE
