# RDL OS (ReallyDamnLightOS)

Un piccolo sistema operativo a 64 bit scritto da zero: bootloader in assembly che passa da real mode a protected mode a long mode, poi salta in un kernel scritto in C.

## Cosa fa oggi

1. Il BIOS carica il boot sector (`boot.asm`, 512 byte a `0x7C00`).
2. Il boot sector legge altri settori dal disco con `INT 13h` e salta a `0x7E00`.
3. `kernel.asm` abilita la linea A20, carica la GDT ed entra in protected mode a 32 bit.
4. Controlla con CPUID che la CPU supporti i 64 bit.
5. Costruisce le tabelle di paginazione (identity mapping dei primi 2 MB), attiva PAE ed EFER.LME, poi la paginazione.
6. Con un far jump entra in long mode a 64 bit e chiama `kmain` (in `kernel.c`, a `0x8200`).
7. `kmain` stampa un messaggio in memoria video (`0xB8000`) con la funzione `print`.

## Struttura

| File | Ruolo |
|------|-------|
| `boot.asm` | Boot sector (real mode), carica il resto dal disco |
| `kernel.asm` | Real → protected → long mode, poi chiama il kernel C |
| `kernel.c` | Kernel in C (freestanding), stampa a schermo |
| `start.bat` | Compila tutto, crea `os.img` e avvia QEMU |

## Requisiti

Su Windows 11 con MSYS2 (terminale UCRT64):

- NASM
- QEMU (`qemu-system-x86_64`)
- GCC, `ld` e `objcopy` (binutils)

## Come si avvia

Dal terminale MSYS2 UCRT64, nella cartella del progetto:

```
./start.bat
```

Compila i sorgenti, crea `os.img` e apre QEMU.

## Limiti noti

- Il boot sector legge solo 3 settori: se il kernel cresce, va aumentato il valore di `AL` prima di `INT 13h`.
- Nessuna IDT, quindi nessun interrupt gestito.
- Nessuna tastiera né driver: per ora solo output a schermo.

## Come l'ho fatto

Ho scritto io il codice, un passo alla volta, imparando dalla documentazione (manuale NASM, OSDev wiki, Intel SDM, manuale GCC e binutils, cppreference). Per capire i concetti e correggere gli errori mi sono fatto aiutare da Claude, Gemini e Perplexity. (Non mi slimate per favore)

## Prossimi passi

- Finire kernel
- Fare shell
- Installer
