all: demo

demo:
	64tass demo.s --long-branch -o $@.prg -l labels.txt

run: demo
	x64 -autostartprgmode 1 -autostart-warp +truedrive +cart demo.prg
