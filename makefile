FILES = cpu.v dmem.v imem.v alu.v regFile.v

all = run

run: $(FILES)
	./run.sh
