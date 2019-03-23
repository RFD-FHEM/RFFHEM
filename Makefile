.PHONY: test UnitTest/makefile clean

UnitTest/makefile: 
	@mkdir -p $(dir $@)
	@test -f $@ || wget -O $@ https://raw.githubusercontent.com/RFD-FHEM/UnitTest/master/makefile

test: UnitTest/makefile	
	${MAKE} -f $< setupEnv test PERL_OPTS="-MDevel::Cover"

clean:  UnitTest/makefile	
	${MAKE} -f $< clean
	@rm UnitTest/makefile || true
