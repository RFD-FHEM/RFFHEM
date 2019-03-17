.PHONY: test 

tests/makefile: 
	echo $(dir $@)
	mkdir -p $(dir $@)
	test -f $@ || wget -O $@ https://raw.githubusercontent.com/RFD-FHEM/UnitTest/master/makefile

test: tests/makefile	
	${MAKE} -f $< test
