# NorCPM-CF - Norwegian Climate Prediction Model for Climate Futures 

## Description 

A flexible, open-source code structure for NorCPM that integrates 
assimilation, model code and setup scripts in a single repository.  

## Installation on Betzy 

### Create github user account and become member of BCPU group 

Visit github.com and create a github user account. 

Send request to become member of BCPU group to ingo.bethke@uib.no 
This is only necessary If you wish to developer the repository.    
 
### Add public ssh key to github profile 

Create public ssh key on Betzy with

    cd $HOME/.ssh 
    ssh-keygen # press enter if asked for password phrase 

This will generate a public ssh key is generate at `$HOME/.ssh/id_rsa.pub`  

Open github.com in your browser, log into your github account and add
your public ssh key from Betzy to your github profile. 

### Install NorCPM code 

Install NorCPM in the nn9039k project space with

    mkdir -p /cluster/projects/nn9039k/people/$USER
    cd /cluster/projects/nn9039k/people/$USER 
    git clone ssh://git@github.com/BjerknesCPU/NorCPM-CF.git NorCPM-CF

NorCPM is installed in `/cluster/projects/nn9039k/people/$USER/NorCPM-CF`

## Setting up and running experiments 

### Make a personal copy of setup scripts and settings 

Scripts for creating and running NorCPM experiments with NorESM1 are in 

    $NORCPMROOT/ensemble/noresm1 

with setting files stored in   

    $NORCPMROOT/ensemble/noresm1/settings 

with NORCPMROOT set to

    $NORCPMROOT=/cluster/projects/nn9039k/people/$USER/NorCPM-CF

The folder "noresm1" is version controlled and its content should only be 
changed if these changes are intended to be committed to the git-repository. 
For testing and development, it is therefore recommended to create a personal 
copy of the folder that is not git controlled. 

This can be done with e.g.

    cd $NORCPMROOT/ensemble/ 
    cp -rpv noresm1 noresm1_$USER

If the folder should not be subject to git-version control then add a new entry 
to the file `$NORCPMROOT/assim/.gitignore`
    noresm1_<myuser>
where <myuser> should we replace with your unix user. 

### Make a personal copy of assimilation scripts and code 

Scripts and code required for assimilation are stored in 

    $NORCPMROOT/assim 

Each subfolder contains a specific assimilation configuration. The environmental 
variable ASSIMROOT set in settings file of the assimilation experiment controls
which assimilation configuration is used. 

The folders are version-controlled and their content should only be changed if 
the changes should be committed to the git-repository. 
For testing and development, it is therefore recommended to create a personal 
copy that is not git controlled. 

This can be done with e.g. 

    cd $NORCPMROOT/assim
    cp -rpvL enkf_cf-system1 enkf_$USER # -L needed for dereferencing sym-links

If the folder should not be subject to git-version control then add a new entry 
to the file `$NORCPMROOT/assim/.gitignore`
    enkf_<myuser>
where <myuser> should we replace with your unix user. 

### Build assimilation code separately from experiment (for testing) 

The assimilation code will be compiled for each new experiment that uses 
assimilation when calling the `create_ensemble.sh` script. 

For debugging and testing, it is also possible to build the assimilation 
code in stand-alone manner with e.g. 

    cd $NORCPMROOT/assim/enkf_cf-system1 
    ./assim_build.sh 

This will compile the assimilation code into 

    /cluster/work/users/$USER/noresm/assim_standalone/enkf_cf-system1 

### Download and install NorESM code

To download NorESM2 from github and install it in the NorCPM-CF structure 
execute  

     cd $NORCPMROOT/ensemble/noresm2
     ./install_noresm2.sh    

### Setting up a new experiment 

Change to your personalized setup folder with 

    cd $NORCPMROOT/ensemble/noresm1_$USER 

Set up a new experiment with 

    ./create_ensemble.sh <path to experiment settings file> [VAR1=value1 VAR2=value2 ...]

where `<path to experiment settings file>` points to one of the experimental 
settings files in the settings sub-directory. 

For example 

    ./create_ensemble.sh ../settings/norcpm1-1_historical.sh ENSSIZE=15
    
will set up a no-assimilation historical experiment with 15 simulation members.

Optional `VAR=value` arguments can be specified to override the defaults from the 
settings file. 

The setup script will prepare individual configuration directories for the 
simulation members in `$NORCPMROOT/cases/$EXPERIMENT` and run directories in 
`$WORK/noresm/$EXPERIMENT`, with `EXPERIMENT` set in the settings file.  

### Running the experiment  

Launch the experiment with

    ./submit_ensemble.sh <path to experiment settings file> [VAR1=value1 VAR2=value2 ...]

Running  

    ./submit_ensemble.sh ../settings/norcpm1-1_historical.sh ENSSIZE=15
    
will submit the historical experiment created in the previous example.

Optional `VAR=value` arguments can be specified to override the defaults for e.g. 
walltime and simulation length (see "Reference for settings variables"). 

If an experiment is resubmitted then it will automatically continue from the 
latest set of restarts present in the run directory. 

The frequency of restart dumps is controlled via the setting variables 
`STOP_OPTION` and `STOP_N`. 

#### Customizing simulation code and output 

The directory of the first simulation member serves as a template for all other
simulation members.

Do the following steps if you wish to apply any changes of the code or 
diagnostic output configuration of th simulation members. 

Prepare the experiment as usual, for example with  

    ./create_ensemble.sh ../settings/norcpm1-1_historical.sh

Change to the configuration directory of the first simulation member in 

   $NORCPMROOT/cases/$EXPERIMENT 

with the value of `EXPERIMENT` set in the settings file.

Make modifications to the code (by placing alternative code in SourceMods sub-
directory and then rebuild) and/or modifications to the output configuration 
(edit bld.nml.csh-files in Buildconf directory).

Rerun the `create_ensemble.sh` script but this time with the arguments 
`SKIP_CASE1=1` and `ASK_BEFORE_REMOVE=0`.

For example, 

    ./create_ensemble.sh ../settings/norcpm1-1_historical.sh SKIP_CASE1=1 ASK_BEFORE_REMOVE=0

The `SKIP_CASE1` argument will force the script to skip the configuration of the 
first simulation member. The settings of the existing first simulation member 
will then be applied to the other simulation members. 

#### Recreating an old experiment and continuing it 

Occasionally, one wants to continue an old experiment that either has been run by 
another user, or, for which the case and run directories for other reasons are 
not intact anymore. 

This can be achieved via setting appropriate values in the settings file of the 
experiment as demonstrated in 
`$NORCPMROOT/ensemble/noresm1/settings/norcpm-cf-system1_assim_19811115_continue20220915.sh`
IMPORTANTLY:

The case names must be identically to original ones. 

The experiment start-date `START_DATE` should also be the same as for 
the original experiment e.g.`1981-11-15`. 

`RUN_TYPE` must be set to `branch`.  

`REF_DATES` should be set to the date at which the experiment should be 
continued, matching the date of the restart files e.g. `2022-09-15`. 

`SKIP_ASSIM_FIRST` should be set to 1 if an assimilation update has already 
been applied to the restart conditions. 

If the above conditions are met then the `run_ensemble.sh` script will 
automatically set `CONTINUE_RUN=TRUE` and the simulations will continue 
from the restart data as if running the original simulations. 

Note that with `CONTINUE_RUN=TRUE` any changes to the diagnostic output or 
external forcing specification in the namelists of CAM and CLM will be ignored.   
   

## Reference for settings variables 

Experiment settings

    EXPERIMENT       : Experiment name (without start-date and member suffixes)
    MEMBER1          : First member, default is 01 
    ENSSIZE          : Number of members in ensemble 
    COMPSET          : Component and forcing configuration of the NorESM    
    RES              : grid configuration, always "f19_g16" for NorCPM1
    START_DATE       : Start date (YYYY-MM-DD) start years for prediction) 

Initialisation settings

    RUN_TYPE           : Default "branch", use "hybrid" only if compset changes  
    REF_EXPERIMENT     : name of reference experiment, including start date  
                       : suffix (if present) but not member suffix  
    REF_SUFFIX_MEMBER1 : suffix of first reference member (e.g., _mem01)
    REF_PATH_LOCAL_MEMBER1 : local path to restart data of first reference member
    REF_PATH_REMOTE_MEMBER1 : remote path to restart data of first reference member
                              (currently not used)
    REF_DATES          : Reference date or dates (multiple only for RUN_TYPE=hybrid) 

Job settings

    STOP_OPTION       : Units for STOP_N, valid values are "nyears", "nmonths" 
                      : and "ndays"; must be "nmonths" for assimilation
    STOP_N            : Simulation length; must be 1 for assimilation 
    RESTART           : Number of times to restart after STOP_N is reached; must 
                      : be 0 for assimilation experiments 
    WALLTIME          : Total walltime for STOP_N*(1+RESTART) simulation length 
    PECOUNT           : CPU setting that defines cores used per simulation
                      : with T=32, S=64, M=96, L=128, X1=502
    ACCOUNT           : CPU account name 
    MAX_PARALLEL_STARCHIVE : threads used for short-term archiving 

General settings 

    CASESROOT         : Location for configuration folders of simulations
    CCSMROOT          : Location of Earth system model code
    ASK_BEFORE_REMOVE : 1=will ask before removing existing cases
    VERBOSE           : 1=set -vx option in all scripts
    SKIP_CASE1        : 1=assume that first simulation member is already set up 
                      : and can serve as templated for other members 
    SDATE_PREFIX      : prefix for start-date, recommended is either empty or "s"
    MEMBER_PREFIX     : prefix for member counter, recommended is either empty or "mem"

Assimilation settings

    ENKFROOT          : Location of assimilation code
    ENSAVE            : diagnose and archive ensemble averages 
    SKIP_ASSIM_START  : 1 = skip DA at experiment start (before running model) 
    SKIP_ASSIM_FIRST  : 1 = skip first assimilation update also if experiment continues   
    RFACTOR_START     : 8 = phase in assimilation at start
                        1 = full assimilation from start
    COMPENSATE_ICE_FRESHWATER : 1=add/remove freshwater to mixed layer to 
                      : componesate for sea ice removed/added by 
                      : assimilation ; must be 0 if ice not updated
    ENKF_NTASKS       : number of mpi-tasks used for EnKF 
    MICOM_INIT_NTASKS_PER_MEMBER : number of tasks used for post-assimilation
                                 : modification of ocean restart files
    OCNGRIDFILE       : path to ocean grid file
    OBSLIST           : observation types to be assimilated
    PRODUCERLIST      : observation products to be assimilated
    REF_PERIODLIST    : reference periods for observation types
    COMBINE_ASSIM     : sequence that controls sequential vs combined 
                      : assimilation, always '0 0 1' for NorCPM1
