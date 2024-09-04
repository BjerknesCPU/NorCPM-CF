# EXPERIMENT DEFAULT SETTINGS 
# USE VARNAME=VALUE ARGUMENT WHEN CALLING SCRIPT TO OVERRIDE DEFAULTS 

# experiment settings
: ${EXPERIMENT:=noresm2-lm_clmda} # case prefix, not including _YYYYMMDD_memXX suffix 
: ${MEMBER1:=1} # first member  
: ${ENSSIZE:=10} # number of members 
: ${COMPSET:=NHISTfrc2}
: ${USER_MODS_DIR:=$SETUPROOT/user_mods/noresm2-lm_clmda_128pes}   
: ${RES:=f19_tn14}
: ${START_DATE:=1996-01-01} # YYYY-MM-DD 

# initialisation settings
: ${RUN_TYPE:=branch} # branch: reference ensemble, hybrid: single reference simulation  
: ${REF_EXPERIMENT:=noresm_ctl_19700101_19700101} # name of reference experiment, including start date if necessary
: ${REF_SUFFIX_MEMBER1:=_mem01} # reference run used to initialise first member for 'branch', all members for 'hybrid' 
: ${REF_PATH_LOCAL_MEMBER1:=$INPUTDATA/ccsm4_init/$REF_EXPERIMENT/$REF_EXPERIMENT$REF_SUFFIX_MEMBER1}
: ${REF_PATH_REMOTE_MEMBER1:=}
: ${REF_DATES:=1996-01-01} # multiple reference dates only for RUN_TYPE=hybrid

# job settings
: ${STOP_OPTION:=nyears} # units for run length specification STOP_N 
: ${STOP_N:=1} # run continuesly for this length 
: ${RESTART:=0} # restart this many times  
: ${WALLTIME:='01:00:00'}
: ${ACCOUNT:=nn9039k}
: ${MAX_PARALLEL_STARCHIVE:=30}

# general settings 
: ${CASESROOT:=$SETUPROOT/../../cases}
: ${NORESMROOT:=$SETUPROOT/../../models/noresm2}
: ${ASK_BEFORE_REMOVE:=0} # 1=will ask before removing existing cases 
: ${VERBOSE:=1} # set -vx option in all scripts
: ${SKIP_CASE1:=0} # skip creating first/template case, assume it exists already 
: ${SDATE_PREFIX:=} # recommended are either empty or "s" 
: ${MEMBER_PREFIX:=mem} # recommended are either empty or "mem" 

# assimilation settings
: ${ASSIMROOT:=$SETUPROOT/../../assim/enkf_noresm2_clmda}
#: ${MEAN_MOD_DIR:=$INPUTDATA_ASSIM/enkf/$RES/NorESM2-LM-CMIP6}
: ${NTASKS_ODA:=128}
#: ${OCNGRIDFILE:=$INPUTDATA/ocn/blom/grid/grid_tnx1v4_20170622.nc}
#: ${OBSLIST:='TEM SAL SST'}
#: ${PRODUCERLIST:='EN422 EN422 NOAA'}
#: ${FREQUENCYLIST:='MONTH MONTH DAY'} 
#: ${REF_PERIODLIST:='1980-2010 1980-2010 1980-2010'}
#: ${COMBINE_ASSIM:='0 0 1'}