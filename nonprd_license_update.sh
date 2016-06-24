#!/bin/bash

## Epic Non Production license key update script
##
## Script will save old license key with current date and replace it with the new non prd key and update the license in cache.
## This script is setup to run on EpicPRDsrv using an file that lists all the NonPrd Epic servers
##
## Rev 1 : 06/23/2016 : michael.litsey@gmail.com : Created



# EPIC_ENVS=`cat /epic/scripts/epic_nonprd_envs | awk '{print $2}'`
EPIC_HOSTS=`cat /epic/scripts/epic_nonprd_envs | awk '{print $1}' | awk '{ if (a[$1]++ == 0) print $0; }' "$@"`
LOGDATE=`date +%Y%m%d`
LOGFILE=/epic/scripts/nonprd_license.log

rm /epic/scripts/nonprd_license.log

printf "\n Starting nonprd_license_update.sh script\n\n"

printf "\n Copying old key to cache.key.$LOGDATE and importing new cache.key \n\n"

for host in `cat /epic/scripts/epic_nonprd_envs`; do
        for key in `ssh epicadm@$host ccontrol qlist | grep running | awk -F'^' '{ print $2 }' | sed -e 's/cachesys/cachesys\/mgr/g'`; do
                echo " copying $key/cache.key to cahce.key.$LOGDATE" >> $LOGFILE
                ssh epicadm@$host cp $key/cache.key $key/cache.key.$LOGDATE >> $LOGFILE
                echo " Replaceing current $key/cache.key with new NonPrdKey" >> $LOGFILE
                ssh epicadm@$host cp /epic/upgrade/cache_keys/cache_nonprd.key $key/cache.key >> $LOGFILE
        done
done

printf "\n Upgrading Licenses \n\n"

for host in `cat /epic/scripts/epic_nonprd_envs`; do
        for env in `ssh epicadm@$host ccontrol qlist | grep running | awk -F'^' '{ print $2 }' | awk -F'/' '{ print $3 }'` ; do
        echo -e "w \$SYSTEM.License.Upgrade()\nh\n" | ssh epicadm@$host csession $env -U %SYS >> $LOGFILE
        echo -e "d \$System.License.ShowSummary()\nh\n" | ssh epicadm@$host csession $env -U %SYS >> $LOGFILE
        done
done

printf "\n All Non Production Environment Licenses Updated \n\n"


exit 0
