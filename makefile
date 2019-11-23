all: demo

demo:
	64tass demo.s -o $@.prg

run: demo
	x64 demo.prg
