#!/bin/bash

if [[ -z "$1" ]] ; then
    echo "No MATLAB executable specified"
    exit 1
fi

if [[ -z "$2" ]] ; then
    echo "No MATLAB script specified"
    exit 1
fi

MATLAB_EXE=$1
MATLAB_SCRIPT=$2

$MATLAB_EXE -nodisplay -nosplash -nodesktop -r "try, run('$MATLAB_SCRIPT'), catch ex, disp(['Exception during $MATLAB_SCRIPT: ' ex.message]), exit(1), end, exit(0); "
if [ $? -eq 0 ]; then
	echo "$MATLAB_EXE: Success running $MATLAB_SCRIPT"
	exit 0;
else
	echo "$MATLAB_EXE: Failure running $MATLAB_SCRIPT"
	exit 1;
fi
