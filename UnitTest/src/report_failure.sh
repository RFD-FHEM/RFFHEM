#!/bin/sh
# set -x
 #TRAVIS_BUILD_ID=552259819
 #TRAVIS_JOB_NUMBER="1580.1"
 #TRAVIS_PULL_REQUEST="584"
 #TRAVIS_REPO_SLUG="RFD-FHEM/RFFHEM"
#  make UnitTest/makefile deploylocalLibs && make -f UnitTest/makefile setupEnv test_DeviceData_rmsg
if [ "$TRAVIS_PULL_REQUEST" != "false" ] ; then
	
	VALUE=$(UnitTest/src/fhemcl.sh 8083 "jsonlist2 test_DeviceData_rmsg test_failure" | jq '.Results[].Readings | del(.[][] | select(. == ""))' | jq -r '.test_failure.Value')
	if [ "$VALUE" != "" ] ; then
		JOBNUM=$TRAVIS_JOB_NUMBER | cut -d "." -f2
		NL="\n"
		printf -v V2 "%b" "<br> $NL$NL$NL" "\`\`\`$VALUE$NL\`\`\`$NL"		
		JSON_STRING=$( jq --slurp --raw-input -n \
                      --arg jn "$TRAVIS_JOB_NUMBER" \
                      --arg bid "$TRAVIS_BUILD_ID" \
                      --arg result "<details><summary>Testdetail $TRAVIS_PERL_VERSION</summary><br><br>$V2</details>" \
                      '{jobnum: $jn, build_id: $bid, comment: $result}' )
		#printf -v JSON_POST %b "$JSON_STRING"
		echo "$JSON_STRING" | curl --retry 5 --retry-max-time 40 -X POST -H "x-api-key: ${AWS_API_KEY}"  -H "Content-Type: application/json" -d @- https://os5upwuzf7.execute-api.eu-central-1.amazonaws.com/Stage/save	fi
	fi
	# curl -H "Authorization: token ${GH_API_KEY}" -X POST -d "{\"body\": \"\<details\>\<summary\>result\</summary\>\`\`\`${VALUE}\`\`\`\</details\>\"}" \"https://api.github.com/repos/${TRAVIS_REPO_SLUG}/issues/${TRAVIS_PULL_REQUEST}/comments"
	# curl -H "Authorization: token ${GH_API_KEY}" -X POST -d "{\"body\": \"\<details\>\<summary\>result\</summary\>\`\`\`${VALUE}\`\`\`\</details\>\"}" \"https://api.github.com/repos/${TRAVIS_REPO_SLUG}/issues/${TRAVIS_PULL_REQUEST}/comments"

fi
# cat test_failure.json | jq '.Results[].Readings | del(.[][] | select(. == ""))' | jq '.test_fail  ure.Value'