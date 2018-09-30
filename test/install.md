# Running unittests # 

To run unittests a Test enviroment is needed. 


### Requirements for 98_UnitTest.pm ###

You should not run the UnitTests on a productive used fhem installation.


1. install required test modules via `cpan Test::Device::SerialPort` `cpan Mock::Sub` and `cpan Test::More`  
On Systems with low memory, use [cpanm](https://metacpan.org/pod/App::cpanminus)
 for installing the packages.

2. copy the module 98_UnitTests.pm into /opt/fhem/FHEM directory

3.Copy the test fhem.cfg provided in this repository for a minimal setup to your fhem directory.
`cp test/fhem.cfg /opt/fhem/fhem-unittest.cfg`

4. Start fhem with the provided config file

Now you can start defining a unittest

```
cd /opt/fhem
perl fhem.pl fhem-unittest.cfg
```


### Requirements for test-runner.sh ### 
Optional you can run tests from the commandline.

Currently test-runner searches logfiles in /opt/fhem. So you can install your test instance of fhem into a separate directoy but you must link the logfile to /opt/fhem  
Unit Testfiles are searched in the directory test.  

If you call `test-runer.sh my_test_1` then this will try to load a file test/my_test_1-definition.

### Writing my first unittest ### 
Define a new test with

defmod my_Test_1 UnitTest dummyDuino ({} ) 

Now you have a placeholder for defining your code.
Open the DEF from this device an put any perl code inside the {} brackets.

Note: the Name dummyDuino must be the name of a existing definition you want to run tests on. If you startet fhem with the provided minimal `fhem-unittest.cfg`, then this Device of type SIGNALduino named dummyDuino.

In your testcode you can run any perl command.

Additionally there are a few variables provided 

$hash = the hash of the UnitTest Definition
$name = The Name of the UnitTest Definition
$target = The Name of the provided Targetdevice which is under test. Provided in DEF from this UnitTest device. In our example dummyDuino.
$targetHash = Hash from the Targetdevice which is under test.

