// Welcome to RDL OS's Kernel!

// Printf function
void print(const char *s) {
    volatile char *vgaAddress = (volatile char *)0xB8000;
    while (*s != '\0') {
        vgaAddress[0] = *s;
        vgaAddress[1] = 0xF;
        s++;
        vgaAddress += 2;        // In the assembly file it is ADD EBX, 2
    }
}

void kmain(void) {
    print("Yoo sta roba funzia");
}