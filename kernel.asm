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
    
GDT_CODE:       ; 32 bit mode non usata dai 64
    DW 0xFFFF
    DW 0x0000
    DB 0x00
    DB 0x9A
    DB 0xCF
    DB 0x00

GDT_CODE_64:    ; Segmento 64 bit. This we use
    DW 0x0000
    DW 0x0000
    DB 0x00
    DB 0x9A         ; Presente, Ring 0, Code, Eseguibile, Leggibile
    DB 0xAF         ; Flag di Long Mode (L=1, Granularità attiva)
    DB 0x00

GDT_DATA:
    DW 0xFFFF
    DW 0x0000
    DB 0x00
    DB 0x92
    DB 0xCF
    DB 0x00

GDT_DESCRIPTION:
    DW $-GDT_NULL-1 ; Limite -> 23 byte (GDT size - 1)
    DD GDT_NULL     ; base = inizio GDT


; Da qui in poi parte la protected mode. La modalta' 32 bit  operativa principale dei processori moderni.
; Permette il lavoro con spazi virtuali indirizzabili con max 4GB di memoria. 
; Unleashes the power of your CPU!
; Prima di entrare in Protected mode bisogna disabilitare gli interrupts, abilitare la linea A20 e loadare
    ; la GDT (Global Descriptor Table) con segmenti per code, stack e data.
; Per scoprire se la CPU e' in Real o Protected mode bisogna vedere il lowest bit del registro cr0 o msw.

ProtectedMode:      ; SII SIAMO IN PROTECTED MODEE devo riinizializzare i puntatori ai segmenti giustamente
    [Bits 32]
    MOV AX, 0x18
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
    
    PUSHFD
    POP EAX
    CMP ECX, EAX
    JZ Uncompatible

    MOV EAX, 0x80000000 ; Chiediamo il limite delle funzioni estese
    CPUID
    CMP EAX, 0x80000001 ; La CPU supporta almeno la leaf 0x80000001?
    JB Uncompatible     ; Se è minore, niente 64-bit :(

    MOV EAX, 0x80000001 ; Ora possiamo chiamare la funzione specifica per le feature avanzate
    CPUID
    BT EDX, 29          ; Controlliamo il bit 29 (Long Mode / 64-bit)
    JNC Uncompatible    ; Se non è attivo, errore!

    ; Iniziamo a settare il paging
    MOV EDI, 0x1000     ; Indirizzo di partenza delle nostre tabelle
    MOV CR3, EDI        ; Lo mettiamo in CR3 che punta alla PML4
    XOR EAX, EAX        ; Vogliamo scrivere zeri
    MOV ECX, 4096       ; Numero di dword da azzerare
    REP STOSD           ; Ripeti per tutto il blocco

    ; Collegamenti di base! (Identity Paging)
    MOV EAX, 0x2000     ; Indirizzo PDPT
    OR EAX, 0b11        ; Flag: Presente (1) + scrivibile (1)
    MOV [0x1000], EAX

    ; Puntatore Page Dir
    MOV EAX, 0x3000     ; Indirizzo Page Directory
    OR EAX, 0b11
    MOV [0x2000], EAX

    ; Mettiamo 2MB dentro la Page Dir 
    MOV EAX, 0b10000011 
    MOV [0x3000], EAX

    ; Per chiunque stia guardando questo codice, NON ho la minima idea di cosa stia succedendo 
    ; nel setup del paging. Il resto si!!!

    ; Abilitiamo PAE (Physical Address Extension) In CR4
    MOV EAX, CR4
    OR EAX, (1 << 5)
    MOV CR4, EAX

    ; Puntiamo CR3 alla PML4
    MOV EAX, 0x1000
    MOV CR3, EAX

    ; Abilitiamo LONG MODE! (64 bitz)!
    MOV ECX, 0xC0000080  ; Numero del registro EFER MSR
    RDMSR                ; Legge l'MSR in EDX:EAX
    OR EAX, (1 << 8)     ; Imposta il bit 8 (Long Mode Enable)
    WRMSR                ; Scrive il valore aggiornato nell'MSR

    ; E finalmente... Si entra in long mode everybody!!
    ; Turn on pagingsss (bit 31 di cr0)
    MOV EAX, CR0
    OR EAX, (1 << 31)
    MOV CR0, EAX

    JMP 0x10:LongMode   ; Se ti ricordi 0x08 era il GDT_CODE sector.

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

LongMode:
    [Bits 64]
    ; Siamo in 64 bitss! Ripuliamo tutto!
    MOV AX, 0
    MOV DS, AX
    MOV ES, AX
    MOV FS, AX
    MOV GS, AX
    MOV SS, AX

    ; Stampiamooo
    MOV RSI, LONG_MODE_MSG
    CALL print_string_64

    ; C func
    CALL 0x8200

    JMP $

print_string_64:
    PUSH RAX
    PUSH RBX
    PUSH RSI 

    MOV RAX, 0
    MOV RBX, 0xB8000

    .print_loop:
        MOV AL, [RSI]
        CMP AL, 0
        JE .print_done

        MOV AH, 0x0F
        MOV [RBX], AX
        ADD RBX, 2
        INC RSI
        JMP .print_loop
    
    .print_done:
        POP RSI
        POP RBX
        POP RAX
        RET

PM_MSG DB 'PM OK!', 0
UNCOMPATIBLE_MSG DB 'You must have a 64-bit processor in order to run ReallyDamnLightOS!', 0
LONG_MODE_MSG DB 'Welcome to Long Mode! Your Hardware is fully compatible with RDL OS', 0
; Siccome c'e' un problema di lettura settori...
times 1024-($-$$) db 0