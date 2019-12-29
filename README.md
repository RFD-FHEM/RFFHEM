SIGNALduino - FHEM Modules development Version 3.3.x
======

[![Coverage Status](https://coveralls.io/repos/github/RFD-FHEM/RFFHEM/badge.svg?branch=master)](https://coveralls.io/github/RFD-FHEM/RFFHEM?branch=master) [![Build Status](https://travis-ci.org/RFD-FHEM/RFFHEM.svg?branch=master)](https://travis-ci.org/RFD-FHEM/RFFHEM)

Counterpart of SIGNALDuino uC, it's the code for FHEM to work with the data received from the uC


Supported Devices / Protocols
======

|Device | Function|
| ------------- | ----------- |
|Arduino Sensor | multi purpose sensor based on arduino |
|Atlantic Security | some sensors (MD-210R / MD-2018R / MD-2003R) |
|Auriol IAN 60107, 114324, 275901, 283582, 297514, 314695 (Lidl) | Weatherstation |
|benon (Semexo OHG) | Remote control (BH-P)|
|BOSCH / Neff | Remote control (SF01 01319004)|
|CAME TOP 432EV | Remote control |
|CTW600 WH1080 | Weather station WH3080 UV/Lux Sensor |
|Clarus | remote power socket|
|Conrad RSL | shutters |
|Dooya | Shutters and blinds from various vendors like Rohrmotor24  |
|Einhel - HS 434/6 | Garagedoor opener |
|Elro DB200, KANGTAI, unitec | wireless bell |
|EM1000WZ | Energy-Monitor |
|ESTO Lighting GmbH KL-RF01 | Remote control |
|EuroChron EFTH-800 | Weather station (temperature and humidity |
|FA21RF | Smoke detector | 
|FHT80 | Roomthermostat (only receive) |
|FHT80TF | door/window switch |
|FLAMINGO | Flamingo smoke detector |
|FS10 | Remote control |
|FS20 | Remote control |
|FT0073 | Weather sensors|
|FreeTec PE-6946 | wireless bell |
|GEIGER GF0x01, GF0x02, GF0x03 | Remote control (compatible to Tedsen) |
|Grothe Mistral SE 03.1| wireless gong |
|Hama TS33C, Bresser Thermo/Hygro Sensor  | Weather sensor |
|Heidemann, Heidemann HX, VTX-BELL | wireless bell |
|Hoermann HSM2, HSM4, HS1-868-BS | Remote control |
|JCHENG SECURITY | PIR |
|KRINNER Lumix, XM21-0| Remote control LED XMAS|
|les led  | Remote controlled LED lamp |
|Livolo | Remote switches and sockets  |
|MANAX MX-RCS250 | Remote control |
|m-e VTX and BASIC | wireless bell |
|Maverick | Wireless BBQ thermometer |
|Medion OR28V | Remote control |
|Mumbi m-FS300 | Remote control |
|NC-3911, NC-3912 | Refrigerator thermometer |
|Novy 840029 | Remote control |
|Opus XT300 | Soil moisture sensor |
|Oregon NR868 | Motion sensor |
|Oregon PIR sensor | motion sensor |
|Oregon Scientific v2 and v3 Devices | Weather sensor |
|QUIGG, LIBRA | Remote control |
|PT2262 and similar Devices | Remote switches like Intertechno V1+V3, Elro, door/window sensors|
|Pollin 551227 | wireless bell |
|RADEMACHER, Roto, Waeco | Remote control (HCS301 chip - only receive) |
|revolt | Energy sensors |
|RH787T, HT12E based | Remote control |
|s014/TCM/Conrad | Weather sensor |
|Somfy RTS | Shutters from Somfy|
|Somfy RTS | Somfy blinds |
|technoline Weatherstation WS 6750/TX70DTH| Weather sensor and station |
|TCM 234759 Tchibo | wireless bell |
|TCM97001,Logilink, Pearl NC, and similar,Lifetec LT3594 | Weather sensor
|TFA 30.3209.02, 30.3208.0, 30.3200, 35.1140.01, 30.3221.02, 30.3222.02 | Weather sensors and stations |
|TS-K108W11 | Doorbell |
|Techmar Garden Lights | Remote control |
|Technoline TX3  | Weather sensor |
|Tedsen SKX1xx, SKX2xx, SKX4xx, SKX6xx | Remote control |
|Visivon remote PT4450  | Remote control |
|VLOXO | wireless bell |
|WH2 | (TFA 30.3157 nur Temp, Hum = 255 -> nicht angezeigt)|
|WS-2000, WS-7000 | Series of various sensors |
|WS-7035, WS-7053, WS7054 | Temperature sensor 433MHz |
||Remote sockets from serval brands|

How to install
======
The Perl modules can be loaded directly into your FHEM installation:

```update all https://raw.githubusercontent.com/RFD-FHEM/RFFHEM/dev-r34/controls_signalduino.txt```

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

