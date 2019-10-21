nasm -f elf32 src/kernel.asm -o build/kernel.o
ld -T build/link.ld -o build/kernel build/kernel.o -build-id=none
objcopy -O elf32-i386 build/kernel build/kernel.elf
..\qemu\qemu-system-i386.exe -kernel build/kernel.elf
pause