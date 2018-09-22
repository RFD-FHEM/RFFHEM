#!/bin/bash


#FHEM_SCRIPT = "/opt/fhem/fhem.pl"
FHEM_SCRIPT='./fhem.pl'

# Start the fhem instance with a test config file
perl $FHEM_SCRIPT fhemtest.cfg

# Add Test definitions online and prepare them for import

CMD=$( sed '/{/,/}/s/;/;;/g' ../test/"$1"-definition.txt)
#echo $CMD
CMD=$(echo "$CMD" | awk 'BEGIN{RS="\n" ; ORS=" ";}{ print }' )
#echo $CMD
RETURN=$(perl $FHEM_SCRIPT 7072 "$CMD")

echo $RETURN

#Wait until test is finished
CMD="{ReadingsVal(\"$1\",\"state\",\"\")}"
until [ $(perl $FHEM_SCRIPT 7072 "$CMD") == "finished" ] ; do 
  sleep 1; 
done

CMD='"{ReadingsVal(\"$1\",\"test_output\",\"\")}"
OUTPUT=$(perl $FHEM_SCRIPT 7072 "$CMD")

CMD='"{ReadingsVal(\"$1\",\"test_failure\",\"\")}"
OUTPUT_FAILED=$(perl $FHEM_SCRIPT 7072 "$CMD")

perl $FHEM_SCRIPT 7072 "shutdown"

echo $OUTPUT

exit 0