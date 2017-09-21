CC=c99
CFLAGS= -Wall -Wextra -pedantic -O0 -g -lm -Wno-unused-variable -Wno-unused-parameter
NASM=nasm
NASMFLAGS=-f elf64 -g -F DWARF

all: main tester

main: main.c obdd_c.o  obdd_asm.o
	$(CC) $(CFLAGS) $^ -o $@

tester: tester.c obdd_c.o obdd_asm.o
	$(CC) $(CFLAGS) $^ -o $@

obdd_asm.o: obdd.asm
	$(NASM) $(NASMFLAGS) $< -o $@

obdd_c.o: obdd.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o
	rm -f main tester
	rm -f salida.caso.*

