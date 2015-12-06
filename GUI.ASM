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
    ;==================
    ; Sprites
    ;==================
    ; Always use multiples of 4 as dimensions! (Faster drawing)

    ; Ball sprite
    _ball   dw BALL_W, BALL_H
            db 0, 0, 4 dup (8), 0, 0
            db 0, 6 dup (8), 0
            db 32 dup (8)
            db 0, 6 dup (8), 0
            db 0, 0, 4 dup (8), 0, 0

    ; Paddle sprite
    _paddle dw PADDLE_W, PADDLE_H
            db 0, 0, 60 dup (7), 0, 0
            db 0, 62 dup (7), 0
            db 64 * 4 dup (7)
            db 0, 62 dup (7), 0
            db 0, 0, 60 dup (7), 0, 0

    ; To clear the ball
    _ball_clear dw BALL_W, BALL_H
                db BALL_W * BALL_H dup (0)

    ; To clear the paddle
    _paddle_clear   dw PADDLE_W, PADDLE_H
                    db PADDLE_W * PADDLE_H dup (0)
   

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

; Render a block
; Parameters: x: x-coordinate
;             y: y-coordinate
;             color: Color
; Returns: none
PROC RenderBlock
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
ENDP RenderBlock

; Render the ball
; Parameters: x, y
; Returns: none
PROC RenderBall
    ARG @@x:dword, @@y:dword

    call drawSprite, offset _ball, offset _screenBuffer, [@@x], [@@y]

    ret
ENDP RenderBall

; Render the paddle
; Parameters: x, y
; Returns: none
PROC RenderPaddle
    ARG @@x:dword, @@y:dword

    call drawSprite, offset _paddle, offset _screenBuffer, [@@x], [@@y]

    ret
ENDP RenderPaddle

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
    

END