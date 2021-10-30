#!/bin/bash
# Heinz-Otto Klas 2019
# send commands to FHEM over HTTP
# if no Argument, show usage
# Optimted by S.Butzek 2019-2020
#set -x
if [ $# -eq 0 ]
then
     echo 'fhemcl Usage'
     echo 'fhemcl [http://<hostName>:]<portNummer> "FHEM command1" "FHEM command2"'
     echo 'fhemcl [http://<hostName>:]<portNummer> filename'
     echo 'echo -e "set Aktor01 toggle" | fhemcl [http://<hostName>:]<portNumber>'
     exit 1
fi
# split the first Argument
IFS=:
arr=("$1")

# if only one then use as portNumber
# or use it as url
IFS=
if [ ${#arr[@]} -eq 1 ]
then
    if  echo "$1" | grep -q -E '^[[:digit:]]+$' 
    then
        hosturl=http://localhost:$1
    else
        echo "$1 is not a Portnumber"
        exit 1
    fi
else
    hosturl=$1
fi

# get Token via http request
token=$(curl -s -D - "localhost:8083/fhem?XHR=1" | awk '/^X-FHEM-csrfToken/{print $2}' | tr -d '\r' )

# reading FHEM command, from Pipe, File or Arguments 
# Check to see if a pipe exists on stdin.
cmdarray=()
if [ -p /dev/stdin ]; then
        #echo "Data was piped to this script!"
        # If we want to read the input line by line
        while IFS= read -r line; do
              cmdarray+=("${line}")
        done
fi

if [ -z $cmdarray ]; then
        # Checking the 2 parameter: filename exist or simple commands
        if [ -f "$2" ]; then
            #echo "Reading File: ${2}"
            readarray -t cmdarray < "${2}"
        else
        #echo "Reading further parameters"
        for ((a=2; a<=${#}; a++)) {
            #echo "command specified: ${!a}"
            cmdarray+=("${!a}")
        }
        fi
fi
if [ -z $cmdarray ]; then
 echo "no command found"
 exit 8
fi 
# loop over all lines stepping up. For stepping down (i=${#cmdarray[*]}; i>0; i--)
for ((i=0; i<${#cmdarray[*]}; i++));do 
    # concat def lines with ending \ to the next line, remove any \r from line
    cmd=${cmdarray[i]//[$'\r']} 

    #while [ "${cmd:${#cmd}-1:1}" = '\' ];do 
    #      ((i++))
    #      cmd=${cmd::-1}$'\n'${cmdarray[i]//[$'\r']}
    #done

    #echo "proceeding Line $((i+1)) : ${cmd}"
    # urlencode loop over String
    cmdu=''
    #for ((pos=0;pos<${#cmd};pos++)); do
    #    c=${cmd:$pos:1}
    #    [[ "$c" =~ [a-zA-Z0-9\.\~\_\-] ]] || printf -v c '%%%02X' "'$c"
    #    cmdu+="$c"
    #done
    #cmd=$cmdu
    # send command to FHEM and filter the output (tested with list...).
    # give only lines between, including the two Tags back, then remove all HTML Tags 
    #curl -s --data "fwcsrf=$token" "$hosturl/fhem?cmd=$cmd" | sed -n '/<pre>/,/<\/pre>/p' |sed 's/<[^>]*>//g'
    #curl -s --data "fwcsrf=$token" "$hosturl/fhem?cmd=$cmd&XHR=1" | sed -n "/<div id='content' >/,/<\/div>/p" |sed 's/<[^>]*>//g'
    #curl -s --data "fwcsrf=$token" "$hosturl/fhem?cmd=$cmd&XHR=1"
    curl -s "$hosturl/fhem" --data "fwcsrf=$token" --data-urlencode "cmd=$cmd" --data-urlencode "XHR=1"
done
