@echo off
nasm -f bin boot.asm -o boot.bin
nasm -f bin kernel.asm -o kernel.bin
gcc -ffreestanding -mno-red-zone -fno-asynchronous-unwind-tables -c kernel.c -o kernel.o
ld --image-base 0 -Ttext 0x8200 --section-start .rdata=0x8400 -e kmain -o kmain.exe kernel.o
objcopy -O binary -j .text -j .rdata kmain.exe kmain.bin
echo Compiling...
sleep 1
echo Creating os.img...
cat boot.bin kernel.bin kmain.bin > os.img
truncate -s 4096 os.img
sleep 1
echo Starting Up...
qemu-system-x86_64 -drive format=raw,file=os.img