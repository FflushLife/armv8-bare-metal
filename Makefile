IMAGE := kernel.elf

CROSS = aarch64-linux-gnu
CC = ${CROSS}-gcc
AS = ${CROSS}-as
LD = ${CROSS}-ld
OBJDUMP = ${CROSS}-objdump
CFLAGS =  -mcpu=cortex-a57 -Wall -Wextra -g

ASM_FLAGS = -mcpu=cortex-a57 -g

OBJS = boot.o

${IMAGE}: linker.ld ${OBJS}
	${LD} -T linker.ld $^ -o $@
	${OBJDUMP} -D kernel.elf > kernel.list

#boot.o: boot.S
%.o: %.S
	# ${AS} ${ASM_FLAGS} -c $< -o $@
	$(CC) ${CFLAGS} -c $< -o $@			# for include header file in assembly

run:
	$(MAKE) kernel.elf
	qemu-system-aarch64 -machine virt -cpu cortex-a57 -nographic -kernel kernel.elf

clean:
	rm -f *.o *.elf *.list

.PHONY: run clean
