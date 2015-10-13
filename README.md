RFFHEM- cresta development branch
======

Counterpart of SIGNALDuino, it's the code for FHEM to work with the data received from the uC


Supported Devices / Protocols
======

|Device | Function|
| ------------- | ----------- |
|TCM97001,Logilink, Pearl NC, and similar | Weather sensor
|PT2262 Devices | Remote switches like Intertechno V1, door/window sensors|
|Conrad RSL | only Funk-Jalousieaktor |
|Oregon Scientific v2 Devices | Weather sensor |
|Technoline TX3  | Weather sensor |
|Cresta TH Sensors| Weather sensor |

Unsupported Devices / Protocols
======
This branch has currently also some unsupported versions

|Arduino Sensor | multi purpose sensor based on arduino |


How to install
======
The Perl modules can be loaded directly into your FHEM installation:

update all https://raw.githubusercontent.com/RFD-FHEM/RFFHEM/dev-cresta/controls_signalduino.txt

Prepare your Arduino nano. Look at http://www.fhemwiki.de/wiki/Datei:Fhemduino_schematic.png
for hardware setup.


Connect the Arduino via USB to your FHEM Server and define the device with it's new port:
Example: define SDuino SIGNALduino /dev/serial/by-id/usb-1a86_USB2.0-Serial-if00-port0@57600
You have to adapt this to your environment.

If you made your setup with an Arduino Nano, you can use this command to load the firmware on your device:
set SDuino flash

If this fails, you may need to install avrdude on your system.
On a raspberry pi it is done via "sudo apt-get install avrdude"


