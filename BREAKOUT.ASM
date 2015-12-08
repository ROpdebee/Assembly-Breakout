;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±?
; Breakout
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±?
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "gui.inc"
INCLUDE "data.asm"

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
    mov [ball_x], BALL_START_X
    mov [ball_y], BALL_START_Y
    mov [paddle_x], PADDLE_START_X
    mov [remaining_blocks], 0

    ; Load the level and draw the blocks
    mov esi, [level_ptr]
    mov edi, offset blocks
    xor eax, eax                    ; Clear out eax, later used for storing color
    xor ecx, ecx                    ; Clear out ecx, used as counter

@@blockLoop:
    movsb                           ; Move the current block from this level into blocks
    mov al, [esi-1]                 ; Get the color of the block, put in AL. Color is 1 byte. Keep in mind that ESI has changed
    call DrawBlock, ecx, eax        ; Have to pass the whole EAX register via stack, hence EAX needed to be cleared before storing the color in AL
    inc ecx
    cmp ecx, BLOCKS_AMOUNT
    jne @@blockLoop                 ; If ECX is not yet at the end, do another block

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

@@levelLoop:
    call InitializeWorld            ; First initialize the world

@@refresh:
    ; First remove the ball and paddle because we're only selectively redrawing the changed parts
    call ClearBallAndPaddle, [ball_x], [ball_y], [paddle_x], PADDLE_Y

    ; Process user input and move paddle
    call ProcessInput
    jz @@gameOver                   ; If zero flag has been set, we should quit the game

    ; Update graphics
    call RenderBall, [ball_x], [ball_y]
    call RenderPaddle, [paddle_x], PADDLE_Y
    call UpdateScreen

    ; Start over
    jmp @@refresh

@@gameOver:                         ; Game has finished
    ; Reset the video mode
    call ResetVideo
    ret
ENDP GameLoop

; Process potential user input and move paddle if necessary
; Sets the zero flag (ZF) when ESC has been pressed
PROC ProcessInput
    USES eax

    mov ah, 01h                     ; Test key pressed
    int 16h                         ; call Keyboard BIOS
    jz @@end                        ; If no key pressed, jump to end

    ; There was input, so process it
    ; We still need to remove the character from the buffer,
    ; even though it's already in AX
    mov ah, 00h                     ; Get input from buffer
    int 16h
    cmp al, 1bh                     ; Test if ESC ASCII value has been entered
    je @@esc                        ; ESC key pressed
    cmp ah, 4bh                     ; Test scan code for left arrow
    je @@left                       ; Left arrow pressed
    cmp ah, 4dh                     ; Test scan code for right arrow
    jne @@end                       ; If right arrow pressed, fall through, else jump to end (can't move paddle vertically)

    ; Right key pressed
    call PaddleMoveRight
    jmp @@end

@@left:
    ; Left key pressed
    call PaddleMoveLeft
    jmp @@end

@@esc:
    ; Escape key pressed
    lahf                            ; Load status flags into AH for modification
    or ah, 40h                      ; Set ZF
    sahf                            ; Store status flags
    ret                             ; End immediately

@@end:
    ; We have to make sure the zero flag is not set because this will end the game even when it's not necessary
    lahf                            ; Load flags into AH
    and ah, 0bfh                    ; Unset zero flag
    sahf                            ; Store flags
    ret
ENDP ProcessInput

; Move the paddle to the left
PROC PaddleMoveLeft
    sub [paddle_x], PADDLE_SPEED    ; Adjust the x position
    jns @@end                       ; If sign bit is not set (paddle_x >= 0), skip the next lines
    ; New x position falls off screen
    mov [paddle_x], 0               ; Reset x position to leftmost position
@@end:
    ret
ENDP PaddleMoveLeft

; Move the paddle to the right
PROC PaddleMoveRight
    add [paddle_x], PADDLE_SPEED    ; Adjust the x position
    cmp [paddle_x], PADDLE_MAX_X
    jle @@end                       ; If paddle_x doesn't fall off the screen (paddle_x <= PADDLE_MAX_X), jump to the next label
    ; New x position falls off screen
    mov [paddle_x], PADDLE_MAX_X
@@end:
    ret
ENDP PaddleMoveRight

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±?
; STACK
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±?
STACK 1000h

END start

