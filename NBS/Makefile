RUNS=array.run \
	array.run \
	arrayp.run \
	aryprm.run \
	atan.run \
	BUG.run \
	checklib.run \
	div.run \
	exp.run \
	fact.run \
	jn.run \
	ln.run \
	Makefile \
	mul.run \
	primes.run \
	raise.run \
	sine.run \
	sqrt1.run \
	sqrt2.run \
	sqrt.run \
	twins.run

PROGRAM=../bc/bc -l
REFERENCE_DIR=../NBS_run_output
DIFF_TOOL=diff

%.run: %.bc
	$(PROGRAM) $< > $@
	$(DIFF_TOOL) $@ $(REFERENCE_DIR)/$@

%.run: %.b
	$(PROGRAM) $< > $@
	$(DIFF_TOOL) $@ $(REFERENCE_DIR)/$@

all: $(RUNS)
	
clean:
	rm -f *.run
