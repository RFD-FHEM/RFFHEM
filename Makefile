/opt/fhem/FHEM/%.pm: FHEM/%.pm
	sudo cp $< $@ 

deploylocal: /opt/fhem/FHEM/00_SIGNALduino.pm /opt/fhem/FHEM/90_SIGNALduino_un.pm /opt/fhem/FHEM/lib/signalduino_protocols.hash
	sudo /etc/init.d/fhem stop || true
	sudo rm /opt/fhem/log/fhem-*.log || true
	sudo cp test/fhem.cfg /opt/fhem/fhem.cfg
	sudo rm /opt/fhem/log/fhem.save || true
	sudo TZ=Europe/Berlin /etc/init.d/fhem start
