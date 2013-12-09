TARGET:=htllc

CAT:=cat
CHMOD:=chmod
ECHO:=echo
RM:=rm
SED:=sed

SRCS:=core.scm view.scm dsl.scm htllc.scm

LOCALCONFIG=Makefile.local


ifeq ($(LOCALCONFIG), $(wildcard $(LOCALCONFIG)))
include $(LOCALCONFIG)
all: $(TARGET)
else
all:
	@$(ECHO) "Missing Makefile.local"
endif

$(TARGET): $(SRCS)
ifeq ($(SCHEME),)
	@$(ECHO) "Please set SCHEME in Makefile.local"
else
ifeq ($(SCHEME),guile)
	$(ECHO) "#! /usr/bin/guile \ " > $(TARGET)
	$(ECHO) "-e main -s" >> $(TARGET)
	$(ECHO) "!#" >> $(TARGET)
	$(CAT) $(SRCS) >> $(TARGET)
	$(SED) -i -r '/\(load \".*\"\)/d' $(TARGET)
	$(CHMOD) 755 $(TARGET)
else
ifeq ($(SCHEME),chez)
	$(ECHO) "#! /usr/bin/petite --script" > $(TARGET)
	$(CAT) $(SRCS) >> $(TARGET)
	$(ECHO) "(main (command-line))" >> $(TARGET)
	$(SED) -i -r '/\(load \".*\"\)/d' $(TARGET)
	$(CHMOD) 755 $(TARGET)
else
	@$(ECHO) "Unsupport scheme implemenation: " $(SCHEME)
endif
endif
endif

clean:
	$(RM) htllc

.PHONY: all clean
