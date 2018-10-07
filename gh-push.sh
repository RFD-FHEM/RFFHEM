#!/bin/sh
set -e

setup_git() {
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
}

commit_controls_file() {
  git add . controls_signalduino.txt
  git commit --message "Travis automatic update controls file: $TRAVIS_BUILD_NUMBER"
}

upload_files() {
  #git remote add origin https://${GH_API_KEY}@github.com/RFD-FHEM/RFFHEM/resources.git > /dev/null 2>&1
  git push origin HEAD:${TRAVIS_BRANCH} 
}

setup_git
commit_controls_file
upload_files