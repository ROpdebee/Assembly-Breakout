;=============================================================================
; Breakout Data and constants
;
; Only holds data for breakout.asm, other data may be defined in other files
;=============================================================================

; Block grid constants
BLOCKS_COLUMNS equ 10
BLOCKS_ROWS equ 6
BLOCKS_AMOUNT equ BLOCKS_COLUMNS * BLOCKS_ROWS

; Ball constants
BALL_START_X equ (SCREEN_WIDTH - BALL_W) / 2
BALL_START_Y equ 100
 
; Paddle constants
PADDLE_START_X equ (SCREEN_WIDTH - PADDLE_W) / 2
PADDLE_Y equ 190
PADDLE_SPEED equ 5  ; Counted in pixels
PADDLE_MAX_X equ SCREEN_WIDTH - PADDLE_W

TOP_SKIP_ROWS equ 2 ; Top rows to skip

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±?
; DATA
;
; Data that is to be passed via stack MUST be declared as a dword (dd),
; otherwise this might cause inconsistensies when calling procedures.
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±?
DATASEG
    ; Message to be displayed in start window
    welcome_msg db ' ', 34 dup ('*'), 0ah, 0dh  ; 0Ah = Line Feed, 0Dh = Carriage Return (both necessary on DOS)
                db " *      Welcome to BREAKOUT!      *", 0ah, 0dh
                db ' ', 34 dup ('*'), 0ah, 0dh
                db 0ah, 0dh
                db " Press any key to start the game or ESC to quit.", 0ah, 0dh
                db " Controls:", 0ah, 0dh
                db 9h, "- Use the left and right arrows to move the paddle.", 0ah, 0dh  ; 9h = Horizontal Tab
                db 9h, "- Press ESC to return to quit the game and return to this screen.", 24h ; 24h = Terminating $

    ; Levels
    ; Note: Should be kept in continuous memory!
    level_1 db BLOCKS_COLUMNS dup (6)
            db BLOCKS_COLUMNS dup (5)
            db BLOCKS_COLUMNS dup (4)
            db BLOCKS_COLUMNS dup (3)
            db BLOCKS_COLUMNS dup (2)
            db BLOCKS_COLUMNS dup (1)

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
    remaining_blocks db ?
    remaining_lives db ?