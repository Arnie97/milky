.PHONY: test install milky build debug release clean distclean testclean

ifeq ($(OS),Windows_NT)
CC       := gcc
endif
CC       ?= gcc
CCFLAGS  += -std=c99 -pedantic -Wall -Wno-switch
MILKYC   ?= milky

SRCDIR   ?= src
OBJDIR   ?= obj
BINDIR   ?= bin
INSTDIR  ?= $(PREFIX)/bin
TESTDIR  ?= tests

MILKSRCS := $(wildcard $(SRCDIR)/*.c.k)
MILKINCS := $(wildcard $(SRCDIR)/*.h.k)
SOURCES  := $(MILKSRCS:%.k=%)
INCLUDES := $(MILKINCS:%.k=%)
OBJECTS  := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

TESTALL  := $(wildcard $(TESTDIR)/*.milk $(TESTDIR)/*.k)
TESTCC   := $(wildcard $(TESTDIR)/*.c.k)
TESTSRCS := $(TESTALL:%.k=%)
TESTASMS := $(TESTCC:$(TESTDIR)/%.c.k=$(OBJDIR)/%.s)

TARGET   := milky

test: $(TESTSRCS) $(TESTASMS)
	@echo "All tests passed! Congratulations!"

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
