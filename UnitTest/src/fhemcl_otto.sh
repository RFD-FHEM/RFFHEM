#!/bin/bash
# Heinz-Otto Klas 2019
# send commands to FHEM over HTTP
# if no Argument, show usage
if [ $# -eq 0 ]
then
     echo ${0##*/}' Usage' 
     echo ${0##*/}' [http://[<user:password@>]<hostName>:]<portNummer> "FHEM command1" "FHEM command2"'
     echo ${0##*/}' [http://[<user:password@>]<hostName>:]<portNummer> filename'
     echo 'echo -e "set Aktor01 toggle" | '${0##*/}' [http://[<user:password@>]<hostName>:]<portNumber>'
     exit 1
fi

# split the first Argument
IFS=:
arr=($1)

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

# get Token and Status
token=;status=
while IFS=':' read key value; do
    case "$key" in
        X-FHEM-csrfToken) token=${value//[[:blank:]]/} ;;
        HTTP*) status="$key"                           ;;
     esac
done < <(curl -s -D - "$hosturl/fhem?XHR=1")
# this should be extended
# now only zero message detected
if [ -z "${status}" ]; then 
        echo "no response from $hosturl"
	exit 1
fi

# reading FHEM command, from Pipe, File or Arguments 
# Check to see if a pipe exists on stdin.
cmdarray=()
if [ -p /dev/stdin ]; then
        # we read the input line by line
        while IFS= read -r line; do
              cmdarray+=("${line}")
        done
else
    # Checking the 2 parameter: filename exist or simple commands
    if [ -f "$2" ]; then
        # echo "Reading File: ${2}"
        readarray -t cmdarray < "${2}"
    else
    # Reading further parameters
        for ((a=2; a<=${#}; a++)); do
            # echo "command specified: ${!a}"
            cmdarray+=("${!a}")
        done
    fi
fi

# loop over all lines stepping up. For stepping down (i=${#cmdarray[*]}; i>0; i--)
for ((i=0; i<${#cmdarray[*]}; i++));do 
    # concat def lines with ending \ to the next line, remove any \r from line
    cmd=${cmdarray[i]//[$'\r']} 

    while [ "${cmd:${#cmd}-1:1}" = '\' ];do 
          ((i++))
          cmd=${cmd::-1}$'\n'${cmdarray[i]//[$'\r']}
    done

    # echo "proceeding Line $((i+1)) : ${cmd}"
    # urlencode loop over String
    cmdu=''
    for ((pos=0;pos<${#cmd};pos++)); do
        c=${cmd:$pos:1}
        [[ "$c" =~ [a-zA-Z0-9\.\~\_\-] ]] || printf -v c '%%%02X' "'$c"
        cmdu+="$c"
    done
    cmd=$cmdu
    # send command to FHEM and filter the output (tested with list...).
    # give only lines between <pre></pre> back, then remove all HTML Tags 
    # may be the argument -m 15 is usefull
    curl -s --data "fwcsrf=$token" "$hosturl/fhem?cmd=$cmd" | sed -n '/<div.*content/,/<\/div>/p' | sed -e '/div/d' -e '/\/pre>/d' -e 's/<[^>]*>//g'
done
