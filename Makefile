.PHONY: test UnitTest/makefile deploylocalLibs clean
space:=
space+=

MAKEFILE_DIR:=$(subst $(space),\$(space),$(shell dirname $(subst $(space),\$(space),$(realpath $(lastword $(MAKEFILE_LIST))))))

deploylocalLibs:
	@cp $(MAKEFILE_DIR)/UnitTest/FHEM/lib/*.pm /opt/fhem/FHEM/lib
	@cp $(MAKEFILE_DIR)/UnitTest/FHEM/lib/*.json /opt/fhem/FHEM/lib

	
UnitTest/makefile: 
	@mkdir -p $(dir $@)
	@test -f $@ || wget -O $@ https://raw.githubusercontent.com/RFD-FHEM/UnitTest/master/makefile

test: UnitTest/makefile deploylocalLibs
	${MAKE} -f $< setupEnv test PERL_OPTS="-MDevel::Cover"

clean:  UnitTest/makefile	
	${MAKE} -f $< clean
	@rm UnitTest/makefile || true

