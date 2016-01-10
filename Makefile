.PHONY: test coverage lcov
.PHONY: install milky build debug release
.PHONY: clean distclean testclean

ifeq ($(OS),Windows_NT)
CC       := gcc
endif
CC       ?= gcc
CCFLAGS  += -std=c99 -pedantic -Wall -Wno-switch
MILKYC   ?= milky

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
DUMMIES  := $(MILKSRCS:%.k=$(LCOVDIR)/%)

TESTALL  := $(wildcard $(TESTDIR)/*.milk $(TESTDIR)/*.k)
TESTCC   := $(wildcard $(TESTDIR)/*.c.k)
TESTSRCS := $(TESTALL:%.k=%)
TESTASMS := $(TESTCC:$(TESTDIR)/%.c.k=$(OBJDIR)/%.s)

TARGET   := milky
LCOVFILE := coverage.run

test: $(TESTSRCS) $(TESTASMS)
	@echo "All tests passed! Congratulations!"

coverage: CCFLAGS += -fprofile-arcs -ftest-coverage
coverage: LDFLAGS += -lgcov
coverage: test

lcov: coverage $(DUMMIES)
	@mkdir -p $(LCOVDIR)
	@lcov -c -d $(OBJDIR) -b $(LCOVDIR) -o $(LCOVDIR)/$(LCOVFILE)
	@genhtml --legend $(LCOVDIR)/$(LCOVFILE) -o $(LCOVDIR)

install: release
	@mkdir -p $(INSTDIR)
	@install -m 0775 $(BINDIR)/$(TARGET) $(INSTDIR)

milky: $(SOURCES) $(INCLUDES)
build: $(BINDIR)/$(TARGET)
debug: CCFLAGS += -ggdb -D _DEBUG
debug: build
release: CCFLAGS += -O3 -s
release: build

$(BINDIR)/$(TARGET): $(OBJECTS)
	@mkdir -p `dirname $@`
	@echo "Linking $@..."
	@$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	@echo "Construction complete."

$(OBJECTS): $(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p `dirname $@`
	@echo "Generating dependencies for $<..."
	@$(call make-depend,$<,$@,$(subst .o,.d,$@))
	@echo "Compiling $<..."
	@$(CC) $(CCFLAGS) -c $< -o $@

$(SOURCES): $(INCLUDES)
$(SOURCES) $(INCLUDES): %: %.k
	@echo "Compiling $< to $@..."
	@$(MILKYC) -o $@ $<
	@printf '\n'

$(DUMMIES): $(LCOVDIR)/%: %.k
	@mkdir -p $(LCOVDIR)/$(SRCDIR)
	@cp $< $@

$(TESTASMS): $(OBJDIR)/%.s: $(TESTDIR)/%.c
	@echo "Compiling test output $<..."
	@$(CC) $(CCFLAGS) -S -c $< -o $@

$(TESTSRCS): %: %.k build
	@echo "Testing $<..."
	@$(BINDIR)/$(TARGET) $<
	@printf '\n'

clean:
	rm -r $(OBJDIR)

distclean: clean
	rm -r $(BINDIR)

testclean:
	rm `find $(TESTDIR) -type f -not -name "*.milk" -not -name "*.k"`

# $(call make-depend,source-file,object-file,depend-file)
define make-depend
	$(CC) -MM -MP -MT $2 -MF $3 $(CCFLAGS) $1
endef
