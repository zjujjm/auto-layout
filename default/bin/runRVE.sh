#!/bin/bash
# Run RVE to see DRC and LVS result
FCMD="AL: from CMD ->| "

echo $FCMD"--Runing RVE"
while getopts 't:m:' arg; do
    case $arg in
        m) 
           TOP_MODULE=$OPTARG
           echo $FCMD"TOP_MODULE is:" $TOP_MODULE;;
        t) 
           CHECK_TYPE=$OPTARG
           echo $FCMD"Runing type is:" $CHECK_TYPE;;
    esac
done

# Ensure this command run at root
if [ x$CHECK_TYPE = 'xdrc' ] && [ ! -z $TOP_MODULE ]; then
    for RESULT in `ls ./result/drcresult/ | grep ^$TOP_MODULE. | grep results` 
    do
        SUMMARY=$SUMMARY' ./result/drcresult/'$RESULT
    done
    calibre -rve -drc $SUMMARY &
elif [ x$CHECK_TYPE = 'xlvs' ] && [ ! -z $TOP_MODULE ]; then
    calibre -rve -lvs ./result/lvsresult/svdb $TOP_MODULE &
else
    echo $FCMD"Invalid checking type, exit"
fi;

