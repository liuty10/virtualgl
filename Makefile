all: rr mesademos diags
ALL: dist mesademos

.PHONY: rr util jpeg mesademos diags clean dist

rr: util jpeg

rr util jpeg mesademos diags:
	cd $@; $(MAKE); cd ..

clean:
	cd rr; $(MAKE) clean; cd ..; \
	cd util; $(MAKE) clean; cd ..; \
	cd jpeg; $(MAKE) clean; cd ..; \
	cd mesademos; $(MAKE) clean; cd ..; \
	cd diags; $(MAKE) clean; cd ..

TOPDIR=.
include Makerules

##########################################################################
ifeq ($(platform), windows)
##########################################################################

ifneq ($(DISTRO),)
WBLDDIR = $(platform)$(subplatform)\\$(DISTRO)
else
WBLDDIR = $(platform)$(subplatform)
endif

ifeq ($(DEBUG), yes)
WBLDDIR := $(WBLDDIR)\\dbg
endif

dist: rr diags
	$(RM) $(WBLDDIR)\$(APPNAME).exe
	makensis //DAPPNAME=$(APPNAME) //DVERSION=$(VERSION) \
		//DBUILD=$(BUILD) //DBLDDIR=$(WBLDDIR) rr.nsi || \
	makensis /DAPPNAME=$(APPNAME) /DVERSION=$(VERSION) \
		/DBUILD=$(BUILD) /DBLDDIR=$(WBLDDIR) rr.nsi  # Cygwin doesn't like the //


##########################################################################
else
##########################################################################

ifeq ($(subplatform),)
RPMARCH = i386
else
RPMARCH = $(ARCH)
endif

ifeq ($(prefix),)
prefix=/usr/local
endif

ifeq ($(cfgdir),)
cfgdir=/etc
endif
lib64dir=lib64
ifeq ($(platform), solaris)
lib64dir=lib/sparcv9
endif
ifeq ($(platform), solx86)
lib64dir=lib/sparcv9
endif

PACKAGENAME = $(APPNAME)
ifeq ($(subplatform), 64)
PACKAGENAME = $(APPNAME)64
endif

ifeq ($(subplatform), 64)
install: rr
	if [ ! -d $(prefix)/bin ]; then mkdir -p $(prefix)/bin; fi
	if [ ! -d $(prefix)/$(lib64dir) ]; then mkdir -p $(prefix)/$(lib64dir); fi
	$(INSTALL) -m 755 $(EDIR)/vglrun64 $(prefix)/bin/vglrun64
	$(INSTALL) -m 755 $(LDIR)/libhpjpeg.$(SHEXT) $(prefix)/$(lib64dir)/libhpjpeg.$(SHEXT)
	$(INSTALL) -m 755 $(LDIR)/librrfaker.$(SHEXT) $(prefix)/$(lib64dir)/librrfaker.$(SHEXT)
	echo Install complete.
else
install: rr
	if [ ! -d $(prefix)/bin ]; then mkdir -p $(prefix)/bin; fi
	if [ ! -d $(prefix)/lib ]; then mkdir -p $(prefix)/lib; fi
	if [ ! -d $(cfgdir) ]; then mkdir -p $(cfgdir); fi
	$(INSTALL) -m 755 rr/rrxclient.sh $(prefix)/bin/vglclient_daemon
	$(INSTALL) -m 755 rr/rrxclient_ssl.sh $(prefix)/bin/vglclient_ssldaemon
	$(INSTALL) -m 755 rr/rrxclient_config $(prefix)/bin/vglclient_config
	$(INSTALL) -m 644 rr/rrcert.cnf $(cfgdir)/vglcert.cnf
	$(INSTALL) -m 644 util/nettest.pem $(cfgdir)/nettest.pem
	$(INSTALL) -m 755 rr/newrrcert $(prefix)/bin/newvglcert
	$(INSTALL) -m 755 $(EDIR)/vglrun $(prefix)/bin/vglrun
	$(INSTALL) -m 755 $(EDIR)/vglclient $(prefix)/bin/vglclient
	$(INSTALL) -m 755 $(LDIR)/libhpjpeg.$(SHEXT) $(prefix)/lib/libhpjpeg.$(SHEXT)
	$(INSTALL) -m 755 $(LDIR)/librrfaker.$(SHEXT) $(prefix)/lib/librrfaker.$(SHEXT)
	$(INSTALL) -m 755 $(EDIR)/tcbench $(prefix)/bin/tcbench
	$(INSTALL) -m 755 $(EDIR)/nettest $(prefix)/bin/nettest
	echo Install complete.
endif

ifeq ($(subplatform), 64)
uninstall:
	$(RM) $(prefix)/bin/vglrun64
	$(RM) $(prefix)/$(lib64dir)/libhpjpeg.$(SHEXT)
	$(RM) $(prefix)/$(lib64dir)/librrfaker.$(SHEXT)
	echo Uninstall complete.
else
uninstall:
	$(prefix)/bin/vglclient_daemon stop || echo Client not installed as a service
	$(prefix)/bin/vglclient_ssldaemon stop || echo Secure client not installed as a service
	$(RM) $(prefix)/bin/vglclient_daemon
	$(RM) $(prefix)/bin/vglclient_ssldaemon
	$(RM) $(prefix)/bin/vglclient_config
	$(RM) $(cfgdir)/vglcert.cnf
	$(RM) $(cfgdir)/nettest.pem
	$(RM) $(prefix)/bin/newvglcert
	$(RM) $(prefix)/bin/vglrun
	$(RM) $(prefix)/bin/vglclient
	$(RM) $(prefix)/lib/libhpjpeg.$(SHEXT)
	$(RM) $(prefix)/lib/librrfaker.$(SHEXT)
	$(RM) $(prefix)/bin/tcbench
	$(RM) $(prefix)/bin/nettest
	echo Uninstall complete.
endif

ifeq ($(platform), linux)

dist: rr diags $(BLDDIR)/rpms/BUILD $(BLDDIR)/rpms/RPMS
	rm -f $(BLDDIR)/$(PACKAGENAME).$(RPMARCH).rpm; \
	rpmbuild -bb --define "_blddir `pwd`/$(BLDDIR)" --define "_curdir `pwd`" --define "_topdir $(BLDDIR)/rpms" \
		--define "_version $(VERSION)" --define "_build $(BUILD)" --define "_bindir $(EDIR)" \
		--define "_libdir $(LDIR)" --define "_appname $(APPNAME)" --target $(RPMARCH) \
		rr.spec; \
	mv $(BLDDIR)/rpms/RPMS/$(RPMARCH)/$(PACKAGENAME)-$(VERSION)-$(BUILD).$(RPMARCH).rpm $(BLDDIR)/$(PACKAGENAME).$(RPMARCH).rpm

$(BLDDIR)/rpms/BUILD:
	mkdir -p $@

$(BLDDIR)/rpms/RPMS:
	mkdir -p $@

endif

ifeq ($(platform), solaris)
dist: sunpkg
endif
ifeq ($(platform), solx86)
dist: sunpkg
endif

PKGDIR = SUNWvgl
PKGNAME = $(PKGDIR)$(subplatform)

.PHONY: sunpkg
sunpkg: rr diags
	rm -rf $(BLDDIR)/pkgbuild
	rm -rf $(BLDDIR)/$(PKGNAME)
	rm -f $(BLDDIR)/$(PKGNAME).pkg.bz2
	mkdir -p $(BLDDIR)/pkgbuild/$(PKGDIR)
	mkdir -p $(BLDDIR)/$(PKGNAME)
	cp copyright $(BLDDIR)
	cp depend $(BLDDIR)
	cp rr$(subplatform).proto $(BLDDIR)
	cat pkginfo$(subplatform).tmpl | sed s/{__VERSION}/$(VERSION)/g | sed s/{__BUILD}/$(BUILD)/g \
		| sed s/{__APPNAME}/$(APPNAME)/g | sed s/{__PKGNAME}/$(PKGNAME)/g >$(BLDDIR)/pkginfo
	$(MAKE) prefix=$(BLDDIR)/pkgbuild/$(PKGDIR) cfgdir=$(BLDDIR)/pkgbuild/$(PKGDIR)/etc install
	cd $(BLDDIR); \
	pkgmk -o -r ./pkgbuild -d . -a `uname -p` -f rr$(subplatform).proto; \
	rm rr$(subplatform).proto copyright depend pkginfo; \
	pkgtrans -s `pwd` `pwd`/$(PKGNAME).pkg $(PKGNAME)
	bzip2 $(BLDDIR)/$(PKGNAME).pkg
	rm -rf $(BLDDIR)/pkgbuild
	rm -rf $(BLDDIR)/$(PKGNAME)

##########################################################################
endif
##########################################################################
