// Welcome to RDL OS's Kernel!

void print(const char *s);      // annuncio, una riga sola
static int cursorPos = 0;
void clear(void);

void kmain(void) {
    clear();
    print("\nInitializing software...\n");
    print("Test 2\n");
    print("Welcome to RDL OS! A Simple, Lightweight OS!\n");
}

void clear(void) {
    volatile char *vgaAddress = (volatile char *)0xB8000;
    for (int i = 0; i < 2000; i++ ) {
        vgaAddress[i * 2] = ' ';
        vgaAddress[i * 2 + 1] = 0xF;
    }
    cursorPos = 0;
}

// Printf function
void print(const char *s) {
    volatile char *vgaAddress = (volatile char *)0xB8000;
    while (*s != '\0') {
        if (*s == '\n') {
            cursorPos = (cursorPos / 80 + 1) * 80;
            s++;
            continue;
        }
        vgaAddress[cursorPos * 2] = *s;
        vgaAddress[cursorPos * 2 + 1] = 0xF;
        cursorPos++;
        s++;
    }
}
