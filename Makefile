
all: run

.PHONY: run
run:
	env `cat .env` swift run
