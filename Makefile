SOURCES = $(shell find src -name '*.c')
OBJS = $(SOURCES:.c=.o)
TESTS = $(shell find tests -name '*.c')
TESTOBJS = $(TESTS:.c=.o)

BISON=bison -y -v
FLEX=flex -P$(YYPREFIX) -olex.yy.c
YYPREFIX=mtex2MML_yy

RM=rm -f
INSTALL=install -c
BINDIR=/usr/local/bin

CURRENT_MAKEFILE  := $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
TEST_DIRECTORY    := $(abspath $(dir $(CURRENT_MAKEFILE)))/tests
CLAR_FIXTURE_PATH := $(TEST_DIRECTORY)/fixtures/
CFLAGS += -Wall -Wextra -Wno-sign-compare -DCLAR_FIXTURE_PATH=\"$(CLAR_FIXTURE_PATH)\" -pedantic -std=gnu99 -iquote inc

all: clean src/y.tab.o src/lex.yy.o libmtex2MML.a

.PHONY: clean
clean:
	git clean -xf src
	# git clean -xf tests

src/y.tab.c:
	$(BISON) -p $(YYPREFIX) -d src/mtex2MML.y
	mv y.output src
	mv y.tab.c src
	mv y.tab.h src

src/lex.yy.c:
	$(FLEX) src/mtex2MML.l
	mv lex.yy.c src

src/y.tab.o:	src/y.tab.c
	$(CC) -c -o src/y.tab.o src/y.tab.c

src/lex.yy.o:	src/lex.yy.c src/y.tab.c
	$(CC) -c -o src/lex.yy.o src/lex.yy.c

libmtex2MML.a: $(OBJS)
	$(AR) crv libmtex2MML.a $(OBJS)
	mkdir -p dist/
	mv libmtex2MML.a dist/
	cp src/mtex2MML.h dist/

.PHONY: test
test: clar.suite tests/helpers.h tests/clar_test.h $(TESTOBJS)
	tests/generate.py tests/
	$(CC) $(CFLAGS) -Wno-implicit-function-declaration $(TESTOBJS) dist/libmtex2MML.a -o tests/testrunner
	./tests/testrunner

clar.suite:
	python tests/generate.py tests/
