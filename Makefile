/opt/fhem/FHEM/%.pm: FHEM/%.pm
	sudo cp $< $@ 
/opt/fhem/FHEM/lib/%.hash: FHEM/lib/%.hash
	sudo cp $< $@ 
98_UnitTest.pm: test/98_unittest.pm
	sudo cp $< /opt/fhem/FHEM/$@
		
deploylocal: /opt/fhem/FHEM/00_SIGNALduino.pm /opt/fhem/FHEM/14_SD_WS.pm 98_UnitTest.pm /opt/fhem/FHEM/90_SIGNALduino_un.pm /opt/fhem/FHEM/lib/signalduino_protocols.hash
	sudo timeout 3 killall -qws2 perl || sudo killall -qws9 perl || true
	sudo rm /opt/fhem/log/fhem-*.log || true
	sudo cp test/fhem.cfg /opt/fhem/fhem.cfg
	sudo rm /opt/fhem/log/fhem.save || true
	TZ=Europe/Berlin 
	cd /opt/fhem && perl -MDevel::Cover fhem.pl fhem.cfg && cd ${TRAVIS_BUILD_DIR}
	
test: deploylocal
	@echo === running 00_SIGNALduino unit tests ===
	test/test-runner.sh test1
	test/test-runner.sh test3
	test/test-runner.sh test4
	test/test-runner.sh test_mu_1
	cp test/*.hash /opt/fhem/FHEM/lib && test/test-runner.sh test_loadprotohash
	test/test-runner.sh test_developid_1
	test/test-runner.sh test_proto46
	test/test-runner.sh test_proto57
	test/test-runner.sh test_proto84
	test/test-runner.sh test_proto85
	test/test-runner.sh test_fingerprint
	test/test-runner.sh test_firmware_download_1
	test/test-runner.sh test_modulematch_1
	@echo === finished 00_SIGNALduino unit tests ===
	sudo timeout 30 killall -vw perl || sudo killall -vws9 perl
