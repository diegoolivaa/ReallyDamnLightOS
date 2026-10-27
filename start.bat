@echo off
nasm -f bin boot.asm -o boot.bin
nasm -f bin kernel.asm -o kernel.bin
ld --image-base 0 -Ttext 0x8200 -e kmain -o kmain.exe kernel.o
objcopy -O binary -j .text kmain.exe kmain.bin
echo Compiling...
sleep 1
echo Creating os.img...
cat boot.bin kernel.bin kmain.bin > os.img
truncate -s 2048 os.img
sleep 1
echo Starting Up...
qemu-system-x86_64 -drive format=raw,file=os.img