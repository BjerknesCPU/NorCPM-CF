# EXPERIMENT DEFAULT SETTINGS 
# USE VARNAME=VALUE ARGUMENT WHEN CALLING SCRIPT TO OVERRIDE DEFAULTS 

# experiment settings
: ${EXPERIMENT:=noresm2-lmesm_free3mem} # case prefix, not including _YYYYMMDD_memXX suffix 
: ${MEMBER1:=1} # first member  
: ${ENSSIZE:=3} # number of members 
: ${COMPSET:=NHISTfrc2esm}
: ${USER_MODS_DIR:=$SETUPROOT/user_mods/noresm2-lmesm_free_128pes}   
: ${RES:=f19_tn14}
: ${START_DATE:=1970-01-01} # YYYY-MM-DD 

# initialisation settings
: ${RUN_TYPE:=hybrid} # branch: reference ensemble, hybrid: single reference simulation  
: ${REF_EXPERIMENT:=NHIST_f19_tn14_20191104esm} # name of reference experiment, including start date if necessary
: ${REF_PATH_LOCAL_MEMBER1:=/cluster/work/users/$USER/restarts/$REF_EXPERIMENT}
: ${REF_DATES:=1975-01-01} # multiple reference dates only for RUN_TYPE=hybrid
: ${ADD_PERTURBATION:=1} # only for RUN_TYPE=hybrid  

# job settings
: ${STOP_OPTION:=nyears} # units for run length specification STOP_N 
: ${STOP_N:=1} # run continuesly for this length 
: ${RESTART:=0} # restart this many times  
: ${WALLTIME:='00:59:00 --qos=devel'}
: ${ACCOUNT:=nn9039k}
: ${MAX_PARALLEL_STARCHIVE:=30}

# general settings 
: ${CASESROOT:=$SETUPROOT/../../cases}
: ${NORESMROOT:=$SETUPROOT/../../model/noresm2}
: ${ASK_BEFORE_REMOVE:=0} # 1=will ask before removing existing cases 
: ${VERBOSE:=1} # set -vx option in all scripts
: ${SKIP_CASE1:=0} # skip creating first/template case, assume it exists already 
: ${SDATE_PREFIX:=} # recommended are either empty or "s" 
: ${MEMBER_PREFIX:=mem} # recommended are either empty or "mem" 
