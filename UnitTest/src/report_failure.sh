#!/bin/bash
 # set -x
 #TRAVIS_BUILD_ID=552259819
 #TRAVIS_JOB_NUMBER="1580.1"
 #TRAVIS_PULL_REQUEST="584"
 #TRAVIS_REPO_SLUG="RFD-FHEM/RFFHEM"
#  make UnitTest/makefile deploylocalLibs && make -f UnitTest/makefile setupEnv test_DeviceData_rmsg
if [ "$TRAVIS_PULL_REQUEST" != "false" ] ; then
	
	VALUE=$(UnitTest/src/fhemcl.sh 8083 "jsonlist2 test_DeviceData_rmsg test_failure" | jq '.Results[].Readings | del(.[][] | select(. == ""))' | jq -r '.test_failure.Value')
	if [ "$VALUE" != "" ] ; then
		#JOBNUM=$TRAVIS_JOB_NUMBER | cut -d "." -f2
		NL="\n"
		printf -v V2 "%b" "$NL$NL$NL" "- **test_DeviceData_rmsg** $NL \`\`\`$VALUE$NL\`\`\`$NL"
		JSON_STRING=$( jq --slurp --raw-input -n \
                      --arg jn "$TRAVIS_JOB_NUMBER" \
                      --arg bid "$TRAVIS_BUILD_ID" \
                      --arg result "<details><summary>${TRAVIS_JOB_NUMBER}: Details Perl ($TRAVIS_PERL_VERSION)</summary>$V2</details>" \
                      '{jobnum: $jn, build_id: $bid, comment: $result}' )
		#printf -v JSON_POST %b "$JSON_STRING"
		echo "$JSON_STRING" | curl --retry 5 --retry-max-time 40 -X POST -H "x-api-key: ${AWS_API_KEY}"  -H "Content-Type: application/json" -d @- https://os5upwuzf7.execute-api.eu-central-1.amazonaws.com/Stage/save
	fi
else
  echo "This is not a pullrequest build. Failures are not reported"
fi
