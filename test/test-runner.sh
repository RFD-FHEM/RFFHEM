#!/bin/bash

# Return 0 when test run is okay
# Return 1 when there was an test error
# Return 254 no connection to fhem process possible
# Return 255 if fhem.pl was not found


FHEM_SCRIPT="/opt/fhem/fhem.pl"
if [ ! -f $FHEM_SCRIPT ]; then
	FHEM_SCRIPT="./fhem/fhem.pl"
	if [ ! -f $FHEM_SCRIPT ]; then
		exit 255
	fi
fi
#printf "Script %s\n" $FHEM_SCRIPT

IFS=
# Start the fhem instance with a test config file
#perl $FHEM_SCRIPT fhemtest.cfg
a=0
# Check if connection to fhem process is possible
while  true 
do 
	perl $FHEM_SCRIPT 7072 \"LIST\" 
	if [ $? -eq 0 ]
	then
		break
	fi
	sleep 3
	
	if [ $a -gt "100" ]  # Limit trys
	then
	  exit 254
	fi
	a=$(($a+1))
done


RETURN=$(perl $FHEM_SCRIPT 7072 "reload 98_UnitTest")  # only for testing
echo $RETURN


echo "--------- Starting test $1 ---------\n\n"

# Load test definitions, and import them to our running instance

CMD=$( sed '/{/,/}/s/;/;;/g' test/"$1"-definition.txt)
#echo $CMD
CMD=$(echo "$CMD" | awk 'BEGIN{RS="\n" ; ORS=" ";}{ print }' )
#echo $CMD
RETURN=$(perl $FHEM_SCRIPT 7072 "$CMD")

echo $RETURN

#Wait until state of current test is finished
#Todo prevent forever loop here
CMD="{ReadingsVal(\"$1\",\"state\",\"\")}"
until [ "$(perl $FHEM_SCRIPT 7072 "$CMD")" == "finished" ] ; do 
  sleep 1; 
done

CMD="{ReadingsVal(\"$1\",\"test_output\",\"\")}"
OUTPUT=$(perl $FHEM_SCRIPT 7072 "$CMD")
OUTPUT=$(echo $OUTPUT | awk '{gsub(/\\n/,"\n")}1')

CMD="{ReadingsVal(\"$1\",\"test_failure\",\"\")}"
OUTPUT_FAILED=$(perl $FHEM_SCRIPT 7072 "$CMD")

	#echo $OUTPUT
	#echo $OUTPUT_FAILED

testlog=$(awk '/Test '"$1"' starts here ---->/,/<---- Test '"$1"' ends here/' /opt/fhem/log/fhem-*.log)
#oklines=$(echo $testlog | egrep ^[[:digit:]]{4}\.[[:digit:]]{2}\.[[:digit:]]{2}[[:space:]][[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}[[:space:]]3:[[:space:]]ok)
#noklines=$(echo $testlog | egrep ^[[:digit:]]{4}\.[[:digit:]]{2}\.[[:digit:]]{2}[[:space:]][[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}[[:space:]]3:[[:space:]]nok)

#echo $testlog

echo "Output of $1:\n\n"
echo $OUTPUT

if [ -z "$OUTPUT_FAILED" ]
then
    if [ $(echo $testlog | grep -Fxc "PERL WARNING") -gt 0 ]
	then
		echo "Warnings in FHEM Log snippet from test run:"
		echo $testlog
		status="ok with warnings"
	else 
		status="ok"
	fi

else
	echo "Errors of test $1:"
	echo $OUTPUT_FAILED

	echo "FHEM Log snippet from test run:"
	echo $testlog
	status="error"
fi

printf "\n\n--------- Test %s: %s ---------\n" $1 $status

if [ $status == "error" ] 
then
 exit 1
fi
exit 0

#perl $FHEM_SCRIPT 7072 "shutdown"
