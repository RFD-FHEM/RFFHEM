SIGNALduino - FHEM Modules stable Version 3.3.2
[![Coverage Status](https://coveralls.io/repos/github/RFD-FHEM/RFFHEM/badge.svg?branch=dev-r33-travis-update)](https://coveralls.io/github/RFD-FHEM/RFFHEM?branch=dev-r33-travis-update) [![Build Status](https://travis-ci.org/RFD-FHEM/RFFHEM.svg?branch=dev-r33-travis-update)](https://travis-ci.org/RFD-FHEM/RFFHEM)
======

Counterpart of SIGNALDuino uC, it's the code for FHEM to work with the data received from the uC


Supported Devices / Protocols
======

|Device | Function|
| ------------- | ----------- |
|TCM97001,Logilink, Pearl NC, and similar,Lifetec LT3594 | Weather sensor
|PT2262 and similar Devices | Remote switches like Intertechno V1+V3, Elro, door/window sensors|
|Conrad RSL | shutters |
|Oregon Scientific v1, v2 and v3 Devices | Weather sensor |
|Oregon PIR sensor | motion sensor |
|Technoline TX3  | Weather sensor |
|Hama TS33C, Bresser Thermo/Hygro Sensor  | Weather sensor |
|Arduino Sensor | multi purpose sensor based on arduino |
|technoline Weatherstation WS 6750/TX70DTH| Weather sensor and station |
||Remote sockets from serval brands|
|CTW600 WH1080 | Weather station WH3080 UV/Lux Sensor |
|TFA 30320902,30320802  | Weather sensor |
|Visivon remote PT4450  | Remote control |
|Einhel - HS 434/6 | Garagedoor opener |
|FA21RF | Smoke detector | 
|Mumbi m-FS300 | remote socket |
|s014/TFA 30.3200/TCM/Conrad | Weather sensor |
|les led  | Remote controlled led lamp |
|Livolo | Remote switches and sockets  |
|Somfy RTS | Somfy blinds |
|Maverick | Wireless BBQ thermometer |
|FLAMINGO | Flamingo smoke detector |
|Dooya | Shutters and blinds from various vendors like Rohrmotor24  |
|Somfy RTS | Shutters from Somfy|
|Opus XT300 | Soil moisture sensor |
|Oregon NR868 | Motion sensor |
|IAN 275901 Lidl | Weatherstation |
|m-e VTX and BASIC | wireless bell |
|FT0073 | Weather sensors|
|revolt | Energy sensors|
|Clarus | remote power socket|
|WH2 | (TFA 30.3157 nur Temp, Hum = 255 -> nicht angezeigt)|#
|TS-K108W11 | Doorbell |
|Bresser 7009994| Temp/Hum Sensor |

How to install
======
The Perl modules can be loaded directly into your FHEM installation:

```update all https://raw.githubusercontent.com/RFD-FHEM/RFFHEM/master/controls_signalduino.txt```

Prepare your Arduino nano. Look at http://www.fhemwiki.de/wiki/Datei:Fhemduino_schematic.png
for hardware setup.


Connect the Arduino via USB to your FHEM Server and define the device with it's new port:
Example: ```define SDuino SIGNALduino /dev/serial/by-id/usb-1a86_USB2.0-Serial-if00-port0@57600```
You have to adapt this to your environment.

If you made your setup with an Arduino Nano, you can use this command to load the firmware on your device:
set SDuino flash

If this fails, you may need to install avrdude on your system.
On a raspberry pi it is done via ```sudo apt-get install avrdude```

More Information
=====
Look at the FHEM Wiki, for more Information: http://www.fhemwiki.de/wiki/SIGNALDuino
Forum thread is at: http://forum.fhem.de/index.php/topic,38831.0.html

