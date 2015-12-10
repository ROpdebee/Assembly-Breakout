;=============================================================================
; Breakout GUI
;=============================================================================

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "gui.inc"
INCLUDE "vga.inc"

; Screen constants
SCREEN_PIXELS equ SCREEN_WIDTH * SCREEN_HEIGHT
VIDEO_MEMORY equ 0a0000h
AMOUNT_OF_COLORS equ 9 ; We'll use 9 different colors

;=============================================================================
; DATA
;=============================================================================
DATASEG
    ; Color palette
    _palette    db 0, 0, 0     ; Color 0 = Black
                db 63, 0, 0    ; Color 1 = Red
                db 63, 31, 0   ; Color 2 = Orange
                db 63, 63, 0   ; Color 3 = Yellow
                db 0, 63, 0    ; Color 4 = Green
                db 0, 0, 63    ; Color 5 = Blue
                db 31, 0, 63   ; Color 6 = Purple
                db 31, 31, 31  ; Color 7 = Gray
                db 63, 63, 63  ; Color 8 = White
    ; Sprites
    INCLUDE "sprites.asm"
   

;=============================================================================
; Uninitialized DATA
;=============================================================================
UDATASEG
    _screenBuffer db SCREEN_PIXELS dup (?)

;=============================================================================
; CODE
;=============================================================================
CODESEG

; Initialize everything necessary for the start of the game,
; such as video modes, color palette etc
PROC InitializeVideo
    USES eax

    ; Set video mode to 320x200 8 bit color
    mov ax, 13h
    int 10h

    ; Set color palette
    call vga_setPalette, offset _palette, 0, AMOUNT_OF_COLORS

    ; Clear video buffer of garbage
    call ClearVideoBuffer           ; Initial color is black

    ; Now clear screen
    call UpdateScreen

    ret                             ; Return to caller
ENDP InitializeVideo

; Reset the video mode
PROC ResetVideo
    USES eax

    ; Clear the screen first, this will get rid of some ugly transitions
    call ClearVideoBuffer
    call UpdateScreen

    ; Set video mode back to original text mode
    mov ax, 3h
    int 10h

    ret
ENDP ResetVideo

; Clear the video buffer
PROC ClearVideoBuffer
    USES edi, ecx, eax

    mov eax, 0                      ; Store color into eax (block of 4 bytes to speed up storing)
    mov ecx, SCREEN_PIXELS / 4      ; Stored in blocks of 4 bytes
    mov edi, offset _screenBuffer   ; Store in screen buffer
    rep stosd
    ret
ENDP ClearVideoBuffer

; Copy buffer to screen
PROC UpdateScreen
    USES edi, esi, ecx

    mov esi, offset _screenBuffer   ; Copy from buffer
    mov edi, VIDEO_MEMORY           ; to screen
    mov ecx, SCREEN_PIXELS / 4      ; all the pixels in blocks of 4 bytes
    call vga_waitVBE                ; Wait for vertical blank as to not interfere with retracing
    rep movsd
    ret
ENDP UpdateScreen

; Draws a sprite to the dstPtr , using SCREEN_WIDTH and SCREEN_HEIGHT, at
; coordinate (x, y)
;
; Sprites are a buffer of DB’s, preceeded with their width and height as DW.
;
; Assumes ds and es are correct.
; Copied from Video mode 13h (video.pdf) by Tim Bruylants, Bob Andries and Peter Schelkens
; Small adjustments made
PROC drawSprite
    ARG @@spritePtr:dword, \
        @@dstPtr:dword, \
        @@x:dword, \
        @@y:dword
    LOCAL @@w:dword, @@h:dword
    USES eax, ebx, ecx, edx, esi, edi

    mov esi, [@@spritePtr]
    xor eax, eax
    lodsw ; read width in AX
    mov [@@w], eax
    lodsw ; read height in AX
    mov [@@h], eax

    mov edi, [@@dstPtr]
    mov eax, [@@y]
    mov ebx, SCREEN_WIDTH
    mul ebx
    add edi, eax
    add edi, [@@x] ; EDI points to first pixel
    mov ecx, [@@h]
@@drawLine:
    push ecx

    mov ecx, [@@w]  ; need to copy a line of the sprite
    shr ecx, 2      ; Divide by 4 because we're moving 4 bytes
    rep movsd       ; copy from esi to edi, 4 bytes at a time, @@w will always be a multiple of 4

    add edi, SCREEN_WIDTH
    sub edi, [@@w] ; edi now points to the next line in dst

    pop ecx
    dec ecx
    jnz @@drawLine

    ret
ENDP drawSprite

; Draw a block
; Parameters: x: x-coordinate
;             y: y-coordinate
;             color: Color
; Returns: none
PROC DrawBlock
    ARG @@x:dword, @@y:dword,\
        @@color:dword
    USES ecx, edi, edx, eax

    mov ecx, 3
    mov eax, [@@color]              ; Color is now in AH
@@storeColor:                       ; Repeat color in each byte of EAX
    shl eax, 8
    mov al, ah
    dec ecx
    jnz @@storeColor

    ; Put start position in EDI
    mov edi, [@@y]
    imul edi, SCREEN_WIDTH          ; Top y position of block
    add edi, [@@x]                  ; Add left x position in block
    ; EDI is now the first pixel of the block
    ; Still needs to point in the screen buffer
    add edi, offset _screenBuffer

    ; Draw the block
    mov edx, BLOCK_H                ; Vertical counter
@@vLine:                            ; Draw a vertical line
    mov ecx, BLOCK_W / 4            ; Horizontal counter
    rep stosd                       ; Put the line in the buffer
    add edi, SCREEN_WIDTH - BLOCK_W ; Move EDI to the start on the next line
    dec edx
    jnz @@vLine                     ; If we're not at the last line, do the next line
    ; The whole block is rendered now
    ret
ENDP DrawBlock

; Draw the ball
; Parameters: x, y
; Returns: none
PROC DrawBall
    ARG @@x:dword, @@y:dword

    call drawSprite, offset _ball, offset _screenBuffer, [@@x], [@@y]

    ret
ENDP DrawBall

; Draw the paddle
; Parameters: x, y
; Returns: none
PROC DrawPaddle
    ARG @@x:dword, @@y:dword

    call drawSprite, offset _paddle, offset _screenBuffer, [@@x], [@@y]

    ret
ENDP DrawPaddle

PROC DrawLife
    ARG @@x:dword, @@y:dword

    call drawSprite, offset _life, offset _screenBuffer, [@@x], [@@y]

    ret
ENDP DrawLife

PROC DrawScoreText
    ARG @@x:dword, @@y:dword

    call drawSprite, offset _score, offset _screenBuffer, [@@x], [@@y]

    ret
ENDP DrawScoreText

PROC DrawDigit
    ARG @@digit:dword, @@x:dword, @@y:dword
    USES ebx

    mov ebx, DIGIT_W * DIGIT_H + 4  ; Amount of bytes for one color = 1 byte per pixel + 2 words for the dimensions of the sprite
    imul ebx, [@@digit]
    add ebx, offset _digits         ; EBX now points to the correct digit sprite
    call drawSprite, ebx, offset _screenBuffer, [@@x], [@@y]
    ret
ENDP DrawDigit

; Clear the ball and paddle from the screen buffer
; Parameters: ball_x, ball_y, paddle_x, paddle_y (dwords)
; Returns: none
PROC ClearBallAndPaddle
    ARG @@ball_x:dword, @@ball_y:dword,\
        @@paddle_x:dword, @@paddle_y:dword

    ; First clear the ball
    call drawSprite, offset _ball_clear, offset _screenBuffer, [@@ball_x], [@@ball_y]

    ; Then clear the paddle
    call drawSprite, offset _paddle_clear, offset _screenBuffer, [@@paddle_x], [@@paddle_y]

    ret
ENDP ClearBallAndPaddle

; Clear the top rows that have been skipped by block generation
PROC ClearTopRows
    USES eax, ecx, edi

    mov ecx, TOP_SKIP_ROWS * SCREEN_WIDTH * BLOCK_H / 4
    xor eax, eax
    mov edi, offset _screenBuffer       ; The top rows start at the very first pixel of the screen 
    rep stosd                           ; Clear out everything
    ret
ENDP ClearTopRows

END