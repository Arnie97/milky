.PHONY: test coverage dummy gcov lcov
.PHONY: install milky build debug release
.PHONY: clean srcclean distclean testclean

CC       ?= gcc
CFLAGS   += -std=c99 -pedantic -Wall -Wno-switch -Wno-unused-value
MILKYC   ?= milky
SHELL    := bash

PREFIX   ?= /usr/local
SRCDIR   ?= src
OBJDIR   ?= obj
BINDIR   ?= bin
INSTDIR  ?= $(PREFIX)/bin
TESTDIR  ?= tests
LCOVDIR  ?= html

MILKSRCS := $(wildcard $(SRCDIR)/*.c.k)
MILKINCS := $(wildcard $(SRCDIR)/*.h.k)
SOURCES  := $(MILKSRCS:%.k=%)
INCLUDES := $(MILKINCS:%.k=%)
OBJECTS  := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
DUMMIES  := $(MILKSRCS:%.k=$(OBJDIR)/%)

TESTALL  := $(wildcard $(TESTDIR)/*.milk $(TESTDIR)/*.k)
TESTCC   := $(wildcard $(TESTDIR)/*.c.k)
TESTSRCS := $(TESTALL:%.k=%)
TESTASMS := $(TESTCC:$(TESTDIR)/%.c.k=$(OBJDIR)/%.s)

TARGET   ?= milky
LCOVFILE ?= coverage.run

test: $(TESTSRCS) $(TESTASMS)
	@echo "All tests passed! Congratulations!"

coverage: CFLAGS  += -fprofile-arcs -ftest-coverage
coverage: LDFLAGS += -lgcov
coverage: test
dummy: $(DUMMIES)

gcov: coverage dummy
	@gcov -o $(OBJDIR) -s $(OBJDIR) $(DUMMIES)

lcov: coverage dummy
	@mkdir -p $(LCOVDIR)
	@lcov -c -d $(OBJDIR) -b $(OBJDIR) -o $(LCOVDIR)/$(LCOVFILE)
	@genhtml --legend $(LCOVDIR)/$(LCOVFILE) -o $(LCOVDIR)

install: release
	@mkdir -p $(INSTDIR)
	@install -m 0775 $(BINDIR)/$(TARGET) $(INSTDIR)

milky: $(SOURCES) $(INCLUDES)
build: $(BINDIR)/$(TARGET)
debug: CFLAGS += -ggdb -D _DEBUG
debug: build
release: CFLAGS += -O3 -s
release: build

$(BINDIR)/$(TARGET): $(OBJECTS)
	@mkdir -p `dirname $@`
	@echo "Linking $@..."
	@$(CC) $^ $(LDFLAGS) -o $@
	@echo "Construction complete."

$(OBJECTS): $(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p `dirname $@`
	@echo "Generating dependencies for $<..."
	@$(call make-depend,$<,$@,$(subst .o,.d,$@))
	@echo "Compiling $<..."
	@$(CC) $(CFLAGS) -c $< -o $@

$(SOURCES): $(INCLUDES)
$(SOURCES) $(INCLUDES): %: %.k
	@echo "Compiling $< to $@..."
	@$(MILKYC) -o $@ $<

$(DUMMIES): $(OBJDIR)/%: %.k
	@mkdir -p $(OBJDIR)/$(SRCDIR)
	@cp $< $@

$(TESTASMS): $(OBJDIR)/%.s: $(TESTDIR)/%.c
	@echo "Compiling test output $<..."
	@$(CC) $(CFLAGS) -S -c $< -o $@

$(TESTSRCS): %: %.k build
	@file=$(notdir $<); \
	exit_status=$${file%%[^0-9]*}; \
	if [ $$exit_status ]; then \
		echo "Testing $< (expected error $$exit_status)..."; \
		$(BINDIR)/$(TARGET) $<; \
		[ $$? -eq $$exit_status ]; \
	else \
		echo "Testing $<..."; \
		$(BINDIR)/$(TARGET) $<; \
	fi

clean: srcclean testclean
	@rm -rv $(OBJDIR) || true

srcclean:
	@rm -rv $(SOURCES) $(INCLUDES) || true

distclean:
	@rm -rv $(BINDIR) || true

testclean:
	@rm -rv $(TESTSRCS) || true

bootstrap:
	@wget -N https://github.com/Arnie97/milky/archive/bootstrap.tar.gz
	@tar -xzvf bootstrap.tar.gz
	@cd milky-bootstrap; make install
	@rm -rf milky-bootstrap

# $(call make-depend,source-file,object-file,depend-file)
define make-depend
	$(CC) -MM -MP -MT $2 -MF $3 $(CFLAGS) $1
endef
