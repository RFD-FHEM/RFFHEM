/opt/fhem/FHEM/%.pm: FHEM/%.pm
	sudo cp $< $@ 
98_UnitTest.pm: test/98_unittest.pm
	sudo cp $< /opt/fhem/FHEM/$@
		
## deploylocal: /opt/fhem/FHEM/00_SIGNALduino.pm /opt/fhem/FHEM/10_FS10.pm /opt/fhem/FHEM/14_SD_WS.pm 98_UnitTest.pm /opt/fhem/FHEM/90_SIGNALduino_un.pm /opt/fhem/FHEM/lib/signalduino_protocols.hash
deploylocal : 98_UnitTest.pm
	sudo cp FHEM/*.pm /opt/fhem/FHEM/
	sudo cp FHEM/lib/*.pm /opt/fhem/FHEM/lib
	sudo cp test/*.json /opt/fhem/FHEM/lib
	sudo cp test/*.pm /opt/fhem/FHEM/lib
	sudo timeout 3 killall -qws2 perl || sudo killall -qws9 perl || true
	sudo rm /opt/fhem/log/fhem-*.log || true
	sudo cp test/fhem.cfg /opt/fhem/fhem.cfg
	sudo rm /opt/fhem/log/fhem.save || true
	TZ=Europe/Berlin 
	cd /opt/fhem && perl -MDevel::Cover fhem.pl fhem.cfg && cd ${TRAVIS_BUILD_DIR}
	
test: deploylocal
	@echo === running commandref test ===
	git --no-pager diff --name-only ${TRAVIS_COMMIT_RANGE} | egrep "\.pm" | xargs -I@ echo -select @ | xargs --no-run-if-empty perl /opt/fhem/contrib/commandref_join.pl 
	@echo === running unit tests ===
	test/test-runner.sh test_modules
	test/test-runner.sh test_SD_Protocols
	test/test-runner.sh test_defineDefaults
	test/test-runner.sh test_callsub_1
	test/test-runner.sh test1
	test/test-runner.sh test3
	test/test-runner.sh test4
	test/test-runner.sh test_mu_1
	test/test-runner.sh test_MS_2
	test/test-runner.sh test_loadprotohash
	test/test-runner.sh test_developid_1
	test/test-runner.sh test_proto44
	test/test-runner.sh test_proto46
	test/test-runner.sh test_proto57
	test/test-runner.sh test_proto84
	test/test-runner.sh test_proto85
	test/test-runner.sh test_fingerprint
	test/test-runner.sh test_firmware_download_1
	test/test-runner.sh test_modulematch_1
	test/test-runner.sh test_sub_SIGNALduino_OSV2
	test/test-runner.sh test_sub_MCTFA
	test/test-runner.sh test_sub_SIGNALduino_getAttrDevelopment
	test/test-runner.sh test_SDWS07
	test/test-runner.sh test_SDWS
	@echo === finished unit tests ===
	sudo timeout 30 killall -vw perl || sudo killall -vws9 perl
