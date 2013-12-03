TARGET:=htllc

CAT:=cat
CHMOD:=chmod
ECHO:=echo
RM:=rm
SED:=sed

SRCS:=core.scm view.scm dsl.scm htllc.scm

all: $(TARGET)

$(TARGET): $(SRCS)
	$(ECHO) "#!/usr/bin/guile \ " > $(TARGET)
	$(ECHO) "-e main -s" >> $(TARGET)
	$(ECHO) "!#" >> $(TARGET)
	$(CAT) $(SRCS) >> $(TARGET)
	$(SED) -i -r '/\(load \".*\"\)/d' $(TARGET)
	$(CHMOD) 755 $(TARGET)

clean:
	$(RM) htllc

.PHONY: all clean
