#!/bin/bash

# Return 0 when test run is okay
# Return 1 when there was an test error
# Return 7 testfile was not found
# Return 254 no connection to fhem process possible
# Return 255 if fhemcl.sh was not found

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

FHEM_SCRIPT="${SELF_DIR}/fhemcl.sh"
FHEM_HOST="localhost"
FHEM_PORT=8083
VERBOSE=0
if [ ! -z $2 ]; then
  if [ $2 = "-v" ]; then  
        VERBOSE=1
  fi
fi


if [ ! -f "$FHEM_SCRIPT" ]; then
		exit 255
fi
TEST_FILE="${SELF_DIR}/../tests/$1-definition.txt";

if [ ! -f "${TEST_FILE}" ]; then
		exit 7
fi


#printf "Script %s\n" $FHEM_SCRIPT

IFS=
# Start the fhem instance with a test config file
#perl $FHEM_SCRIPT fhemtest.cfg
a=0
# Check if connection to fhem process is possible
while  true 
do 
	# get Token via http request and check if server is responsive
	FHEM_HTTPHEADER=$(curl -s -f -D - "$FHEM_HOST:$FHEM_PORT/fhem?XHR=1")

	if [ $? == 0 ] 
	then
		break
	fi
	sleep 3
	
	if [ $a -gt "1000" ]  # Limit trys
	then
	  exit 254
	fi
	a=$((a+1))
done
FHEM_TOKEN=$(echo $FHEM_HTTPHEADER | awk '/^X-FHEM-csrfToken/{print $2}')

#RETURN=$(echo "reload 98_UnitTest" | /bin/nc localhost 7072)
#echo $RETURN


printf "\n\n--------- Starting test %s-definition.txt: ---------\n" "$1" 
# Execute rereadcfg to get a clean setup
#REREADCFG=$(timeout 60 $FHEM_SCRIPT $FHEM_PORT "shutdown restart")
#echo "Response from stutdown restart: ${REREADCFG}\n" 

# Load test definitions, and import them to our running instance
oIFS=$IFS
IFS=$'\n'  # Split into array at every "linebreak" 
CMD=($(sed 's/\(;\)/\1\1/g' ${TEST_FILE} ) )

printf -v DEF "%s\n" "${CMD[@]}"
IFS=$oIFS
unset oIFS  
#CMD=$DEF

 # delimiter string
delimiter=";;;;"
 #length of main string
strLen=${#DEF}
#length of delimiter string
dLen=${#delimiter}
#iterator for length of string
i=0
#length tracker for ongoing substring
wordLen=0
#starting position for ongoing substring
strP=0
CMD=()
while [ $i -lt $strLen ]; do
    if [ $delimiter == ${DEF:$i:$dLen} ]; then
        CMD+=(${DEF:strP:$wordLen})
        strP=$(( i + dLen ))
        wordLen=0
        i=$(( i + dLen ))
    fi
    i=$(( i + 1 ))
    wordLen=$(( wordLen + 1 ))
done
CMD+=(${DEF:strP:$wordLen})
#declare -p CMD
unset DEF

rm -f /opt/fhem/log/fhem-*$1.log

for i in "${CMD[@]}"; do
	RETURN=$(timeout 60 $FHEM_SCRIPT $FHEM_PORT "$i")
	#echo "$RETURN"
done

#Wait until state of current test is finished
#Todo prevent forever loop here
#CMD="{ReadingsVal(\"$1\",\"state\",\"\");;}"
CMD="list $1 state"
CMD_RET=""
a=0

until [[ "$CMD_RET" =~ "finished" ]] ; do 
  sleep 0.2; 
  CMD_RET=$(timeout 60 $FHEM_SCRIPT $FHEM_PORT "$CMD")
  if [ $a -gt "100" ]  # Limit trys
  then
  exit 254
  fi
  a=$((a+1))

done

##
## 
##
#CMD="{ReadingsVal(\"$1\",\"test_output\",\"\")}"
#OUTPUT=$($FHEM_SCRIPT $FHEM_PORT "$CMD")
#OUTPUT=$(echo "$OUTPUT" | awk '{gsub(/\\n/,"\n")}1')
CMD="jsonlist2 $1 test_output test_failure todo_output"
OUTPUT=$($FHEM_SCRIPT $FHEM_PORT "$CMD" | jq '.Results[].Readings | {test_output, test_failure, todo_output} | del(.[][] | select(. == ""))')
#OUTPUT=$(curl -s --data "fwcsrf=$FHEM_TOKEN" "$FHEM_HOST:$FHEM_PORT/fhem?cmd=$CMD&XHR=1" | jq '.Results[].Readings | {test_output, test_failure, todo_output} | del(.[][] | select(. == ""))')
OUTPUT_FAILED=$(echo $OUTPUT | jq '.test_failure.Value')
testlog=$(awk '/Test '"$1-definition.txt"' starts here ---->/,/<---- Test '"$1-definition.txt"' ends here/' /opt/fhem/log/fhem-*$1.log)

OUTPUT_CLEAN=$(echo $OUTPUT | jq -r '.[].Value')

# Remove lines with null and print output
printf "Output of %s:\n\n%s" "$1" "${OUTPUT_CLEAN//null}"
OUTPUT_FAILED=${OUTPUT_FAILED//null}

if [ -z "$OUTPUT_FAILED"  ]
then
#    if { [ $(echo $testlog | grep -Fxc "PERL WARNING") -gt 0 ] || [ $VERBOSE -eq 1 ]; }
    if { [ $(grep -Fxc "PERL WARNING" /opt/fhem/log/fhem-*$1.log) -gt 0 ] || [ $VERBOSE -eq 1 ]; }
	then
		echo "Warnings in FHEM Log snippet from test run:"
		echo "$testlog"
		status="ok with warnings"
	else 
		status="ok"
	fi

else
	echo "Errors of test $1:"
	echo "$OUTPUT_FAILED"

	echo "FHEM Log snippet from test run:"
	echo "$testlog"
	status="error"
fi

printf "\n\n--------- Test %s-definition.txt: %s ---------\n" "$1" "$status"

if [ $status == "error" ] 
then
 exit 1
fi
exit 0

#perl $FHEM_SCRIPT 7072 "shutdown"
