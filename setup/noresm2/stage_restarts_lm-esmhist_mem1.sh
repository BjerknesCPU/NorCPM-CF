#!/bin/sh -evx 

ADIR=/nird/projects/NS9560K/noresm/cases
CASE=NHIST_f19_tn14_20191104esm
RESDIR=/cluster/work/users/$USER/restarts
START_DATES='1975-01-01-00000 1980-01-01-00000 1985-01-01-00000' 
START_DATES='1970-01-01-00000' 

for START_DATE in $START_DATES
do
  mkdir -p $RESDIR/$CASE/rest/$START_DATE
  cd $RESDIR/$CASE/rest/$START_DATE 
  cp -uv $ADIR/$CASE/rest/$START_DATE/* . 
  find . -name "*.gz" -exec gunzip -f {} \; 
done
echo DONE

