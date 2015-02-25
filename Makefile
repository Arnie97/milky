.PHONY: test build clean distclean

ifeq ($(OS),Windows_NT)
CC       := gcc
endif
CC       ?= gcc
CCFLAGS  += -std=c99 -pedantic -Wall -Wno-switch -O3 -D _DEBUG
MILKYC   ?= milky

SRCDIR   ?= src
OBJDIR   ?= obj
BINDIR   ?= bin
TESTSDIR ?= tests

SOURCES  := $(wildcard $(SRCDIR)/*.c)
INCLUDES := $(wildcard $(SRCDIR)/*.h)
OBJECTS  := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
TESTS    := $(wildcard $(TESTSDIR)/*.milk)
TARGET   := milky

test: build $(TESTS)
	$(foreach TESTFILE,$(TESTS),$(call do-test))
	@echo "All tests passed! Congratulations!"

build: $(BINDIR)/$(TARGET)

$(BINDIR)/$(TARGET): $(OBJECTS)
	@mkdir -p `dirname $@`
	@echo "Linking $@..."
	@$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	@echo "Well done."

$(OBJECTS): $(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p `dirname $@`
	@echo "Generating dependencies for $<..."
	@$(call make-depend,$<,$@,$(subst .o,.d,$@))
	@echo "Compiling $<..."
	@$(CC) $(CCFLAGS) -c $< -o $@

clean:
	rm -r $(OBJDIR)

distclean: clean
	rm -r $(BINDIR)

define do-test
	@echo "Running test $(TESTFILE)..."
	@$(BINDIR)/$(TARGET) $(TESTFILE)
	@echo "Test $(TESTFILE) passed."
endef

# $(call make-depend,source-file,object-file,depend-file)
define make-depend
	$(CC) -MM -MP -MT $2 -MF $3 $(CCFLAGS) $1
endef
