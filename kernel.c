// Welcome to RDL OS's Kernel!

void print(const char *s);      // annuncio, una riga sola
static int cursorPos = 0;

void kmain(void) {
    print("Yoo sta roba funzia\n");
    print("Test 2\n");
    print("Welcome to RDL OS! A Simple, Lightweight OS!\n");
}

// Printf function
void print(const char *s) {
    volatile char *vgaAddress = (volatile char *)0xB8000;
    while (*s != '\0') {
        vgaAddress[cursorPos * 2] = *s;
        vgaAddress[cursorPos * 2 + 1] = 0xF;
        if (*s == '\n') {
            cursorPos = (cursorPos / 80 + 1) * 80;
        }
        cursorPos++;
        s++;
    }
}
