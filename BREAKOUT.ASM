;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±?
; Breakout
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±?
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "gui.inc"

BLOCKS_COLUMNS equ 10
BLOCKS_ROWS equ 6
BLOCKS_AMOUNT equ BLOCKS_COLUMNS * BLOCKS_ROWS

BALL_START_X equ (SCREEN_WIDTH - BALL_W) / 2
BALL_START_Y equ 100

PADDLE_START_X equ (SCREEN_WIDTH - PADDLE_W) / 2
PADDLE_Y equ 190

TOP_SKIP_ROWS equ 2 ; Top rows to skip

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±?
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±?
CODESEG

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°?
; Entry To ASM Code
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°?
start:
    sti                             ; Set The Interrupt Flag
    cld                             ; Clear The Direction Flag

    push ds                         ; Put value of DS register on the stack
    pop es                          ; And write this value to ES

@@gameStart:
    call GameEntry                  ; Start window, freeze for input
    ; ASCII code now in AL

    cmp al, 1bh
    je @@quit                       ; If ESC has been pressed, exit immediately
    call InitializeVideo            ; Else initialize the video mode
    call GameLoop                   ; and start the game loop
    jmp @@gameStart                 ; Go back to the start window when GameLoop returned (game is over)

@@quit:                             ; Quit game
    mov eax, 4c00h                  ; AH = 4Ch - Exit To DOS
    int 21h                         ; DOS INT 21h


; Print welcome message and instructions and wait for keyboard input
PROC GameEntry
    ARG none RETURNS eax
    USES edx

    ; Print welcome message and instructions
    mov ah, 09h                     ; DOS - Print String
    mov edx, offset welcome_msg
    int 21h                         ; DOS INT 21h - Will print string

    ; Wait for keyboard input
    mov ah, 00h
    int 16h

    ret
ENDP GameEntry

; Initializes the game world and draws the starting environment
PROC InitializeWorld
    USES ecx, esi, edi, eax

    ; Move ball and paddle to default positions
    mov [word ptr offset ball_x], BALL_START_X
    mov [byte ptr offset ball_y], BALL_START_Y
    mov [word ptr offset paddle_x], PADDLE_START_X
    mov [byte ptr offset remaining_blocks], 0

    ; Load the level and draw the blocks
    mov esi, [level_ptr]
    mov edi, offset blocks
    xor eax, eax                    ; Clear out eax, later used for storing color
    xor ecx, ecx                    ; Clear out ecx, used as counter

@@blockloop:
    movsb                           ; Move the current block from this level into blocks
    mov al, [esi-1]                 ; Get the color of the block, put in AL. Color is 1 byte. Keep in mind that ESI has changed
    call DrawBlock, ecx, eax        ; Have to pass the whole EAX register via stack, hence EAX needed to be cleared before storing the color in AL
    inc ecx
    cmp ecx, BLOCKS_AMOUNT
    jne @@blockloop                 ; If ECX is not yet at the end, do another block

    ret
ENDP InitializeWorld

; Convert a block number to a valid coordinate and draw a block on this coordinate
; Parameters: block: A block number
;             color: The block's color
; Returns: none
PROC DrawBlock
    ARG @@block:dword, @@color:dword
    USES ebx, eax, edx

    mov eax, [@@block]              ; Argument block in bl
    xor edx, edx                    ; Clear out edx for division

    ; Calculate row and column number
    mov ebx, BLOCKS_COLUMNS         ; Division by BLOCKS_COLUMNS
    idiv ebx                        ; Argument size is 4 bytes, so dividend is edx:eax, quotient (row) now in eax, remainder (column) in edx

    ; Calculate y coordinate from row
    ; Be careful not to put blocks in the top rows that should be left blank
    add eax, TOP_SKIP_ROWS
    imul eax, BLOCK_H               ; y coordinate now in eax

    ; Calculate x coordinate from column
    imul edx, BLOCK_W               ; x coordinate now in edx

    ; Add to block count
    mov ebx, [@@color]
    cmp ebx, 0
    jz @@empty                      ; Not a block if it's coloured black, so bypass the next line
    add [remaining_blocks], 1
@@empty:

    ; Render the block with these coordinates and the color
    call RenderBlock, edx, eax, [@@color]

    ret
ENDP DrawBlock

; Main game loop of the game
PROC GameLoop
    USES eax

@@levelloop:
    call InitializeWorld
    call RenderBall, [ball_x], [ball_y]
    call RenderPaddle, [paddle_x], PADDLE_Y

    call UpdateScreen
    
    mov ah, 0
    int 16h

@@game_over:                        ; Game has finished
    ; Reset the video mode
    call ResetVideo
    ret
ENDP GameLoop


;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±?
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±?
DATASEG
    welcome_msg db "Welcome to BREAKOUT!", 0ah, 0dh   ; Line feed and carriage return
                db "Press any key to start the game or ESC to quit.", 24h ; Terminating $

    ; Levels
    ; Note: Should be kept in continuous memory!
    level_1 db BLOCKS_AMOUNT dup (1)

    level_ptr dd offset level_1     ; Will point to the current level
    level_end dd offset level_ptr   ; Will point to the end of the levels



;=============================================================================
; Uninitialized DATA
;=============================================================================
UDATASEG
    blocks      db BLOCKS_AMOUNT dup (?)
    ball_x      dd ?    ; x position of the ball (as dword because will be passed as argument via stack)
    ball_y      dd ?    ; y position of the ball
    paddle_x    dd ?    ; x position of the paddle
    remaining_blocks dw ?

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±?
; STACK
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±?
STACK 1000h

END start

