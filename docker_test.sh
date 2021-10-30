#!/bin/bash

# set -x
# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

usage() { echo "Usage: $0 [-d] [-v] [-v] [-p] [-f] [-u] [-m <ModuleName>] [-t <testname>]" 1>&2; exit 1; }

startContainer() {
    sudo service docker start 
    sudo docker-compose -f $DOCKER_COMPOSE_FILE start  || sudo docker-compose -f $DOCKER_COMPOSE_FILE up -d
}

# Initialize our own variables:
output_file=""
verbose=0

! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
    exit 1
fi
OPTIONS=dpfuvm:,t:
LONGOPTS=dockerstart,perlmodules,fhemmodules,unittestmodule,verbose,modulename:,testname:

! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

DOCKER_COMPOSE_FILE=~/docker/test-fhem/docker-compose.yml
DOCKER_FHEM_ROOT=~/docker/test-fhem/app/


P=n F=n U=n V= TESTNAME= D=
MODULENAME=[0-9][0-9]_*

# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -d|--dockerstart)
            D=y
            shift
            ;;
        -p|--perlmodules)
            P='y'
            shift
            ;;
        -f|--fhemmodules)
            F='y'
            shift
            ;;
        -u)
            U='y'
            shift
            ;;
        -v|--verbose)
            V='-v'
            shift
            ;;
        -m|--modulename)
            MODULENAME=$2
            shift 2
            ;;
        -t|--testname)
            TESTNAME=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            usage
            exit 3
            ;;
    esac
done

 if [[ $P == 'y' ]]; then
    sudo cp -r  ./t/FHEM/lib $DOCKER_FHEM_ROOT/FHEM/lib/
    sudo cp -r ./FHEM $DOCKER_FHEM_ROOT 
    [[ $D == 'y' ]]  && startContainer
    sudo docker-compose -f $DOCKER_COMPOSE_FILE exec fhem /bin/bash -c "prove $V -r --exec 'perl fhem.pl -t' t/FHEM/${MODULENAME}/${TESTNAME}"

fi

 if [[ $F == 'y' ]]; then
    mkdir -p ${DOCKER_FHEM_ROOT}../ut/tests && sudo cp -r ./UnitTest/tests/* ${DOCKER_FHEM_ROOT}../ut/tests
    sudo cp -r  ./t/FHEM/${MODULENAME} $DOCKER_FHEM_ROOT/t/FHEM 
    sudo cp -r ./FHEM $DOCKER_FHEM_ROOT 
    [[ $D == 'y' ]]  && startContainer
    sudo docker-compose -f $DOCKER_COMPOSE_FILE exec fhem /bin/bash -c "cp /opt/UnitTest_FHEM/FHEM/*.pm ./FHEM"
    sudo docker-compose -f $DOCKER_COMPOSE_FILE exec fhem /bin/bash -c "prove $V -I FHEM -r --exec 'perl fhem.pl -t' t/FHEM/${MODULENAME}/${TESTNAME}"
fi

 if [[ $U == 'y' ]]; then

    sudo cp -r ./UnitTest/* ${DOCKER_FHEM_ROOT}../ut
    sudo cp -r ./FHEM $DOCKER_FHEM_ROOT 
    [[ $D == 'y' ]]  && startContainer
    sudo docker-compose -f $DOCKER_COMPOSE_FILE up fhem_ut 
fi


[[ $D == 'y' ]] && [[ $U == 'n' ]] && [[ $F == 'n' ]] && [[ $P == 'n' ]] && startContainer





