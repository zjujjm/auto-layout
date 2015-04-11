#!/bin/bash
# Build rule for LVS and DRC, templates for streamout and cdl out
# -t CHECK_TYPE
# -m TOP_MODULE
# -c CONTENT
# Usage: buildRule.sh -t lvs|drc -m TOP_MODULE -c "TOP_MODULE=XX"
FCMD="AL: from CMD ->| "

echo $FCMD"--Replacing parameters"
while getopts 't:m:c:r:' arg; do
    case $arg in
        m) 
           TOP_MODULE=$OPTARG
           echo $FCMD"TOP_MODULE is:" $TOP_MODULE;;
        t) 
           CHECK_TYPE=$OPTARG
           echo $FCMD"Runing type is:" $CHECK_TYPE;;
        r)
           RUL_NAME=$OPTARG;;
        c)
           CONTENT=$OPTARG;;
    esac
done
shift $((OPTIND -1))

# Ensure this command run at root
if [ $CHECK_TYPE = 'lvs' ]; then
    TARGET_FILE=./result/${CHECK_TYPE}result/${TOP_MODULE}.${CHECK_TYPE}.rul
    cp ./default/$CHECK_TYPE.rule.default $TARGET_FILE
elif [ $CHECK_TYPE = 'drc' ]; then
    TARGET_FILE=./result/${CHECK_TYPE}result/${TOP_MODULE}.${RUL_NAME}.${CHECK_TYPE}.rul
    cp ./default/$CHECK_TYPE.rule.default $TARGET_FILE
elif [ $CHECK_TYPE = 'CDL' ]; then
    TARGET_FILE=./${CHECK_TYPE}/si.env
    cp ./default/si.env.default $TARGET_FILE
elif [ $CHECK_TYPE = 'GDS' ]; then
    TARGET_FILE=./${CHECK_TYPE}/${TOP_MODULE}.streamout.setup
    cp ./default/streamout.default $TARGET_FILE
elif ([ -z $CHECK_TYPE ] && [ -z $TOP_MODULE ]); then
    echo $FCMD"Input variable error"
fi;

if [ ! -z "$CONTENT" ]; then
    for WORD in $CONTENT
    do
        TARGET=$(echo $WORD | cut -d '=' -f1)
        REPLACEMENT=$(echo $WORD | cut -d '=' -f2)
        echo "Replace" $TARGET "with" $REPLACEMENT
        sed -i "s:${TARGET}:${REPLACEMENT}:g" $TARGET_FILE
    done
fi;

