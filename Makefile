.PHONY: test build debug release clean distclean

ifeq ($(OS),Windows_NT)
CC       := gcc
endif
CC       ?= gcc
CCFLAGS  += -std=c99 -pedantic -Wall -Wno-switch
MILKYC   ?= milky

SRCDIR   ?= src
OBJDIR   ?= obj
BINDIR   ?= bin
TESTSDIR ?= tests

SOURCES  := $(wildcard $(SRCDIR)/*.c)
INCLUDES := $(wildcard $(SRCDIR)/*.h)
OBJECTS  := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
TESTS    := $(wildcard $(TESTSDIR)/*.milk $(TESTSDIR)/*.k)
TARGET   := milky

test: build $(TESTS)
	$(foreach TESTFILE,$(TESTS),$(call do-test))
	@echo "All tests passed! Congratulations!"

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

clean:
	rm -r $(OBJDIR)

distclean: clean
	rm -r $(BINDIR)

define do-test
	@echo "Testing $(TESTFILE)..."
	@$(BINDIR)/$(TARGET) $(TESTFILE)
	@printf '\n\n'

endef

# $(call make-depend,source-file,object-file,depend-file)
define make-depend
	$(CC) -MM -MP -MT $2 -MF $3 $(CCFLAGS) $1
endef
