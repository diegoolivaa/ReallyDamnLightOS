; BOOTLOADER Real, Protected Mode
; Author: Diego Oliva!
; Date: 27/10/26

[ORG 0x7C00]            ; Org -> origin. Serve a stabilire l'indirizzo
                        ; di memoria di partenza al quale il programma
                        ; presume di essere caricato.
                        ; 7C00 dove viene loadato il bootloader che e' un kb sotto 0x08000
USE16                   ; Real mode

JMP MAIN

MAIN:
    MOV AL, 'W'         ; Put "W" into AL
    MOV AH, 0Eh         ; Settare AH a 0Eh (funzione teletype)
    INT 10h             ; Chiama interrupt BIOS
    MOV AL, 'e'         ; Put "e" into AL
    MOV AH, 0Eh         ; Settare AH a 0Eh (funzione teletype)
    INT 10h             ; Chiama interrupt BIOS
    MOV AL, 'l'         ; Put "l" into AL
    MOV AH, 0Eh         ; Settare AH a 0Eh (funzione teletype)
    INT 10h             ; Chiama interrupt BIOS
    MOV AL, 'c'         ; Put "c" into AL
    MOV AH, 0Eh         ; Settare AH a 0Eh (funzione teletype)
    INT 10h             ; Chiama interrupt BIOS
    MOV AL, 'o'         ; Put "o" into AL
    MOV AH, 0Eh         ; Settare AH a 0Eh (funzione teletype)
    INT 10h             ; Chiama interrupt BIOS
    MOV AL, 'm'         ; Put "m" into AL
    MOV AH, 0Eh         ; Settare AH a 0Eh (funzione teletype)
    INT 10h             ; Chiama interrupt BIOS
    MOV AL, 'e'         ; Put "e" into AL
    MOV AH, 0Eh         ; Settare AH a 0Eh (funzione teletype)
    INT 10h             ; Chiama interrupt BIOS
    XOR AX, AX          ; Da qua in poi leggo il secondo settore.
    MOV ES, AX          ; Sposto nell'extra segment (da dove partire) il registro ax
    
    MOV AH, 0h
    MOV DL, 80H
    INT 13H
    JC ERRORE
    
    MOV AH, 2H          ; Read
    MOV AL, 4H          ; Settori da leggere
    MOV BX, 7E00H       ; ES:BX -> SEGMENT:OFFSET
    MOV CH, 0h          ; Old BIOS conventional HDD settings.
    MOV CL, 2H
    MOV DH, 0h
    MOV DL, 80H
    INT 13H             ; Eseguo l'azione di READ. Copio in RAM il settore 2.
    JC ERRORE
    JMP 7E00H           ; Salto al settore 2.

ERRORE:
    MOV AL, 'E'         
    MOV AH, 0Eh         
    INT 10h            
    MOV AL, 'R'         
    MOV AH, 0Eh        
    INT 10h           
    MOV AL, 'R'        
    MOV AH, 0Eh    
    INT 10h            
    MOV AL, 'O'      
    MOV AH, 0Eh     
    INT 10h            
    MOV AL, 'R'         
    MOV AH, 0Eh      
    INT 10h             
    JMP $

times 510-($-$$) db 0   ; Riempe di zeri tutto lo spazio fino al byte 510, cosi' ci sta la firma.
dw 0xAA55               ; Firma speciale!! Serve per dire al BIOS che questo e' un programma avviabile!