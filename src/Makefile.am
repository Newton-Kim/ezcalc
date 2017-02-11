bin_PROGRAMS=ezcalc
ezcalc_SOURCES=main.cc parse.yy scan.ll procstack.cc
ezcalc_LDADD=-lezvm
AM_CPPFLAGS=-I../../include -std=c++11
BUILT_SOURCES=parse.hh
AM_YFLAGS=-d --warning=all
CLEANFILES=parse.cc scan.cc parse.hh parse.output
