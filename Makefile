.PHONY: test build debug release clean distclean testclean

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

SOURCES  := $(wildcard $(SRCDIR)/*.c)
INCLUDES := $(wildcard $(SRCDIR)/*.h)
OBJECTS  := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
TARGET   := milky

TEST_ALL     := $(wildcard $(TESTDIR)/*.milk $(TESTDIR)/*.k)
TEST_GCC     := $(wildcard $(TESTDIR)/*.c.k)
TEST_SOURCES := $(TEST_ALL:$(TESTDIR)/%.k=$(TESTDIR)/%)
TEST_OBJECTS := $(TEST_GCC:$(TESTDIR)/%.c.k=$(OBJDIR)/%.o)

test: $(TEST_SOURCES) $(TEST_OBJECTS)
	@echo "All tests passed! Congratulations!"

install: release
	@mkdir -p $(INSTDIR)
	@install -m 0775 $(BINDIR)/$(TARGET) $(INSTDIR)

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

$(TEST_OBJECTS): $(OBJDIR)/%.o: $(TESTDIR)/%.c
	@mkdir -p `dirname $@`
	@echo "Generating dependencies for $<..."
	@$(call make-depend,$<,$@,$(subst .o,.d,$@))
	@echo "Compiling $<..."
	@$(CC) $(CCFLAGS) -c $< -o $@

$(TEST_SOURCES): $(TESTDIR)/%: $(TESTDIR)/%.k build
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
