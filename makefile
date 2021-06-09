all: exec

exec: calc.s
	nasm -f elf calc.s -o calc.o
	gcc -m32 -Wall -g calc.o -o calc
	rm calc.o
.PHONY: clean
clean:
	rm -rf ./*.o calc