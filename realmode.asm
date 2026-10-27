[ORG 0x7E00]
USE16

; SETTORE 2 CHECK
MOV AL, 'O'         ; Put "A" into AL
MOV AH, 0Eh         ; Settare AH a 0Eh (funzione teletype)
INT 10h             ; Chiama interrupt BIOS
MOV AL, 'K'         ; Put "A" into AL
MOV AH, 0Eh         ; Settare AH a 0Eh (funzione teletype)
INT 10h             ; Chiama interrupt BIOS

CLI                 ; clear interrupt flag.
; Fast A20 Gate per usare tutta la memoria.
IN AL, 92H
OR AL, 2
OUT 92H, AL
LGDT [GDT_DESCRIPTION]
MOV EAX, CR0
OR EAX, 1
MOV CR0, EAX
JMP 0x08:ProtectedMode

; Dichiarazione segmenti della GDT. Non si capisce molto ma piu' avanti la capiro'.
GDT_NULL:
    DQ 0H
    
GDT_CODE:
    DW 0xFFFF
    DW 0x0000
    DB 0x00
    DB 0x9A
    DB 0xCF
    DB 0x00

GDT_DATA:
    DW 0xFFFF
    DW 0x0000
    DB 0x00
    DB 0x92
    DB 0xCF
    DB 0x00

GDT_DESCRIPTION:
    DW 0x17         ; Limite -> 23 byte (GDT size - 1)
    DD GDT_NULL     ; base = inizio GDT


; Da qui in poi parte la protected mode. La modalta' 32 bit  operativa principale dei processori moderni.
; Permette il lavoro con spazi virtuali indirizzabili con max 4GB di memoria. 
; Unleashes the power of your CPU!
; Prima di entrare in Protected mode bisogna disabilitare gli interrupts, abilitare la linea A20 e loadare
    ; la GDT (Global Descriptor Table) con segmenti per code, stack e data.
; Per scoprire se la CPU e' in Real o Protected mode bisogna vedere il lowest bit del registro cr0 o msw.

ProtectedMode:      ; SII SIAMO IN PROTECTED MODEE devo riinizializzare i puntatori ai segmenti giustamente
    [Bits 32]
    MOV AX, 0x10
    MOV DS, AX
    MOV ES, AX
    MOV SS, AX
    MOV ESP, 0x90000
    MOV ESI, PM_MSG
    CALL print_string

    PUSHFD          ; Qui c'e' il controllo CPUID. Se abbiamo processore 64 bit allora ok. Senno' stop!
    POP EAX
    MOV ECX, EAX
    XOR EAX, (1<<21); Controllo invertendo il 21 esimo bit del registro EFLAGS
    PUSH EAX
    POPFD

    CMP ECX, EAX
    JNZ Uncompatible

    MOV EAX, 0x80000000 ; Controllo funzioni estese 
    CPUID
    CMP EAX, 0x80000001 ; Ce le hai?
    JB Uncompatible     ; Se e' piu' basso -> CPU troppo vecchia.

    JMP $

print_string:        ; Funzione print!
    PUSHAD           ; Pusha sullo stack tutti i registri a 16 bit general purpose
    MOV EBX, 0xB8000 ; Dove inizia la memoria VGA (reg BX in 16 bit)
.loop:
    MOV AL, [ESI]   ; Sposto in AL il carattere da leggere [ESI]
    CMP AL, 0       ; Se il carattere e' 0 done
    JE .done 
    MOV AH, 0x0F    ; Colore carattere
    MOV [EBX], AX   ; Effettiva stampa
    ADD EBX, 2      ; + 2 perche' in 000 c'e' la lettera ed in 001 c'e' il colore!
    INC ESI         ; Next char
    JMP .loop       ; Rifai
.done: 
    POPAD           ; Restore registers
    RET             ; Return to ProtectedMode

Uncompatible:
    MOV ESI, UNCOMPATIBLE_MSG
    CALL print_string
    JMP $

PM_MSG DB 'PM OK!', 0
UNCOMPATIBLE_MSG DB 'You must have a 64-bit procesor in order to run ReallyDamnLightOS!', 0
; Siccome c'e' un problema di lettura settori...
times 512-($-$$) db 0