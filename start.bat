@echo off
nasm -f bin boot.asm -o boot.bin
nasm -f bin kernel.asm -o kernel.bin
echo Compiling...
sleep 1
echo Creating os.img...
cat boot.bin kernel.bin > os.img
truncate -s 2048 os.img
sleep 1
echo Starting Up...
qemu-system-x86_64 -drive format=raw,file=os.img