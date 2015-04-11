#!/bin/bash
# Linking library and cds.lib
FCMD="AL: from CMD ->| "
VALID_VAR=0
VALID_LIB=0

export MGC_CALIBRE_LAYOUT_SERVER=8888
echo $FCMD"--Linking library to local dir"
while getopts 'l:p:' arg; do
    case $arg in
        l) 
           LIBRARY_NAME=$OPTARG
           echo $FCMD"Library name is:" $LIBRARY_NAME;;
        p) 
           LIBRARY_PATH=$OPTARG
           echo $FCMD"Library path is:" $LIBRARY_PATH;;
    esac
done

# Ensure this command run at root
echo $FCMD"The target libary is "$LIBRARY_NAME
echo $FCMD"--Vadidating variables:"

if [ -z $LIBRARY_NAME ]; then
    echo $FCMD"Library name is not assigned"
elif [ -z $LIBRARY_PATH ]; then
    echo $FCMD"Library path is not assigned"
else
    echo $FCMD"Variables valid"
    VALID_VAR=1
fi;

echo $FCMD"--Vadidating library and links:"
if [ ! -d $LIBRARY_PATH/$LIBRARY_NAME ]; then
    echo $FCMD"Source library is not valid"
elif [ -a library/$LIBRARY_NAME ]; then
    echo $FCMD"Link exists, pass";
else 
    echo $FCMD"Library valid"
    VALID_LIB=1
fi;

if ([ $VALID_VAR -eq 1 ] && [ $VALID_LIB -eq 1 ]); then
    echo $FCMD"Vadidating passed, building link"; 
    ln -s $LIBRARY_PATH/$LIBRARY_NAME library/$LIBRARY_NAME;
else
    echo $FCMD"Vadidating failed, exiting"; 
fi;

# Link cds.lib
echo $FCMD"--Linking cds.lib file"
if [ ! -f $LIBRARY_PATH/cds.lib ]; then
    echo $FCMD"File cds.lib is not valid"
else
    echo $FCMD"Valid, Linking";
    ln -sf $LIBRARY_PATH/cds.lib library/cds.lib 
fi;

