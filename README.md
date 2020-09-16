SIGNALduino - FHEM Modules development Version 3.5.1

[![Coverage Status](https://coveralls.io/repos/github/RFD-FHEM/RFFHEM/badge.svg?branch=dev-r35_xFSK)](https://coveralls.io/github/RFD-FHEM/RFFHEM?branch=dev-r35_xFSK) [![Build Status](https://travis-ci.org/RFD-FHEM/RFFHEM.svg?branch=dev-r35_xFSK)](https://travis-ci.org/RFD-FHEM/RFFHEM)

Counterpart of SIGNALDuino uC, it's the code for FHEM to work with the data received from the uC


Supported Devices / Protocols
======

|Device | Function|
| ------------- | ----------- |
|Ambient Weather F007T, F007TP, F007TH | Thermo-Hygrometer, Thermometer |
|Arduino Sensor | multi purpose sensor based on arduino |
|Atlantic Security | some sensors (MD-210R / MD_230R / MD-2018R / MD-2003R) |
|Auriol IAN 60107, 114324, 275901, 283582, 297514, 314695 (Lidl) | Weather station |
|BF-301 | Remote control|
|benon (Semexo OHG) | Remote control (BH-P)|
|BOSCH / Neff / Refsta Topdraft | Remote control (SF01 01319004, SF01 01319004 v2)|
|CAME TOP 432EV | Remote control |
|CTW600, WH1080, WH2315 | Weather station |
|Clarus | remote power socket|
|Conrad RSL | shutters |
|Dooya | Shutters and blinds from various vendors like Rohrmotor24  |
|Einhell - HS 434/6 | Garagedoor opener |
|Elro DB200, KANGTAI, unitec | wireless bell |
|EM1000WZ | Energy-Monitor |
|ESTO Lighting GmbH KL-RF01 | Remote control |
|EuroChron EFTH-800, EFS-3110A | Weather station (temperature and humidity) |
|FA21RF | Smoke detector | 
|FHT80 | Roomthermostat (only receive) |
|FHT80TF | door/window switch |
|FLAMINGO | Flamingo smoke detector |
|FS10 | Remote control |
|FS20 | Remote control |
|FT0073 | Weather sensors|
|FreeTec PE-6946 | wireless bell |
|Froggit FT007T, FT007TP, FT007TH | Thermo-Hygrometer, Thermometer |
|GEA-028DB | Radio door chime |
|GEIGER GF0x01, GF0x02, GF0x03 | Remote control (compatible to Tedsen) |
|Grothe Mistral SE 03.1| wireless gong |
|GT-9000| Remote control based on protocol GT-9000 with encoding (EASY HOME RCT DS1, Tec Star)|
|Hama TS33C, Bresser Thermo/Hygro Sensor  | Weather sensor |
|Heidemann, Heidemann HX, VTX-BELL | wireless bell |
|Hoermann HSM2, HSM4, HS1-868-BS | Remote control |
|JCHENG SECURITY | PIR Detector |
|KRINNER Lumix, XM21-0| Remote control LED XMAS|
|les led  | Remote controlled LED lamp |
|Livolo | Remote switches and sockets  |
|MANAX MX-RCS250 | Remote control |
|m-e VTX and BASIC | wireless bell |
|Maverick | Wireless BBQ thermometer |
|Medion OR28V | Remote control |
|Momento | Remote control for wireless digital picture frame |
|Mumbi m-FS300 | Remote control |
|Navaris 44344.04 | Touch light switch |
|NC-3911, NC-3912 | Refrigerator thermometer |
|Novy 840029, 840039 | Remote control |
|Opus XT300 | Soil moisture sensor |
|Oregon PIR sensor, NR868 | Motion sensor |
|Oregon Scientific v2 and v3 Devices | Weather sensor |
|LIBRA, LIDL, MANDOLYN, QUIGG | Remote control TR-502MSV (compatible GT-7008BS, GT-FSI-04, DMV-7008S, Powerfix RCB-I 3600) |
|PT2262 and similar Devices | Remote switches like Intertechno V1+V3, Elro, door/window sensors|
|Pollin 551227 | wireless bell |
|RADEMACHER, Roto, Waeco | Remote control (HCS301 chip - only receive) |
|RH787T, HT12E based | Remote control |
|RIO, enjoy motors HS |  Remote control |
|revolt | Energy sensors |
|s014/TCM/Conrad | Weather sensor |
|Somfy RTS | Shutters from Somfy|
|Somfy RTS | Somfy blinds |
|technoline Weatherstation WS 6750/TX70DTH| Weather sensor and station |
|TCM 234759 Tchibo | wireless bell |
|TCM97001,Logilink, Pearl NC, and similar,Lifetec LT3594 | Weather sensor |
|TFA 30.3200, 30.3208.02, 30.3209.02, 30.3221.02, 30.3222.02, 30.3228.02, 30.3229.02, 35.1140.01 | Weather sensors and stations |
|TS-K108W11 | wireless bell |
|Techmar Garden Lights | Remote control |
|Technoline TX3  | Weather sensor |
|Tedsen SKX1xx, SKX2xx, SKX4xx, SKX6xx | Remote control |
|TR60C-1 | Remote control with touch screen |
|Visivon remote PT4450  | Remote control |
|VLOXO | wireless bell |
|WH2 | (TFA 30.3157 nur Temp, Hum = 255 -> nicht angezeigt)|
|WH2315, WH3080 | UV/Lux Sensor |
|WS-2000, WS-7000 | Series of various sensors |
|WS-7035, WS-7053, WS7054 | Temperature sensor 433MHz |
|xavax | Remote control |
||Remote sockets from serval brands|

How to install
======
The Perl modules can be loaded directly into your FHEM installation:

```update all https://raw.githubusercontent.com/RFD-FHEM/RFFHEM/dev-r35_xFSK/controls_signalduino.txt```

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

