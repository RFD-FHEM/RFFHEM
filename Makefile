/opt/fhem/FHEM/%.pm: FHEM/%.pm
	sudo cp $< $@ 
/opt/fhem/FHEM/lib/%.hash: FHEM/lib/%.hash
	sudo cp $< $@ 
98_UnitTest.pm: test/98_unittest.pm
	sudo cp $< /opt/fhem/FHEM/$@
		
deploylocal: /opt/fhem/FHEM/00_SIGNALduino.pm 98_UnitTest.pm /opt/fhem/FHEM/90_SIGNALduino_un.pm /opt/fhem/FHEM/lib/signalduino_protocols.hash
	sudo service fhem stop || true
	sudo rm /opt/fhem/log/fhem-*.log || true
	sudo cp test/fhem.cfg /opt/fhem/fhem.cfg
	sudo rm /opt/fhem/log/fhem.save || true
	TZ=Europe/Berlin service fhem start

test: deploylocal
	@echo === running 00_SIGNALduino unit tests ===
	test/unittest.sh 00-list-dummyduino
	test/test-runner.sh test3
	@echo === finished 00_SIGNALduino unit tests ===
