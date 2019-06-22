#!/bin/sh
# set -x
# TRAVIS_BUILD_ID=547435645
# TRAVIS_JOB_NUMBER="1555.1"

#  make UnitTest/makefile deploylocalLibs && make -f UnitTest/makefile setupEnv test_DeviceData_rmsg
if [ "$TRAVIS_PULL_REQUEST" != "false" ] ; then
	
	VALUE=$(UnitTest/src/fhemcl.sh 8083 "jsonlist2 test_DeviceData_rmsg test_failure" | jq '.Results[].Readings | del(.[][] | select(. == ""))' | jq -r '.test_failure.Value')
	if [ "$VALUE" != "" ] ; then
		JOBNUM=$TRAVIS_JOB_NUMBER | cut -d "." -f2
		JSON_STRING=$( jq -n \
					  --arg jn "$TRAVIS_JOB_NUMBER" \
					  --arg bid "$TRAVIS_BUILD_ID" \
					  --arg result "<details><summary>$VALUE</summary>" \
					  '{jobnum: $jn, build_id: $bid, comment: $result}' )
		curl -X POST  -H "x-api-key: qhIo6E5YIR89SZmgOSZzr3lz44v83oRp3GBorJvA"  -H "Content-Type: application/json" -d "$JSON_STRING" https://os5upwuzf7.execute-api.eu-central-1.amazonaws.com/Stage/save
	fi
	
	# curl -H "Authorization: token ${GH_API_KEY}" -X POST \
	# -d "{\"body\": \"\<details\>\<summary\>result\</summary\>\`\`\`${VALUE}\`\`\`\</details\>\"}" \
	# "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/issues/${TRAVIS_PULL_REQUEST}/comments"
fi
# cat test_failure.json | jq '.Results[].Readings | del(.[][] | select(. == ""))' | jq '.test_fail  ure.Value'