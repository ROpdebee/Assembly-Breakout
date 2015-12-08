;=============================================================================
; Breakout Data and constants
;
; Only holds data for breakout.asm, other data may be defined in other files
;=============================================================================

; Misc constants
TOP_SKIP_ROWS equ 2     ; Top rows to skip
STARTING_LIVES equ 5    ; Amount of lives the player starts with

; Block grid constants
BLOCKS_COLUMNS equ 10
BLOCKS_ROWS equ 6
BLOCKS_AMOUNT equ BLOCKS_COLUMNS * BLOCKS_ROWS
BLOCKS_BOTTOM equ (BLOCKS_ROWS + TOP_SKIP_ROWS) * BLOCK_H - 1
BLOCKS_TOP equ TOP_SKIP_ROWS * BLOCK_H

; Ball constants
BALL_START_X equ (SCREEN_WIDTH - BALL_W) / 2
BALL_START_Y equ 100
BALL_MAX_Y equ SCREEN_HEIGHT
BALL_MAX_X equ SCREEN_WIDTH - BALL_W
BALL_START_X_SPEED equ 0
BALL_START_Y_SPEED equ 1
 
; Paddle constants
PADDLE_START_X equ (SCREEN_WIDTH - PADDLE_W) / 2
PADDLE_Y equ 190
PADDLE_SPEED equ 10  ; Counted in pixels
PADDLE_MAX_X equ SCREEN_WIDTH - PADDLE_W
PADDLE_BOTTOM equ PADDLE_Y + PADDLE_H - 1
PADDLE_ZONE_1 equ 8     ; First 8 pixels of the paddle belong to zone 1
PADDLE_ZONE_2 equ 12    ; Next 12 pixels belong to zone 2
PADDLE_ZONE_3 equ 24    ; Next 24 pixels belong to zone 3
PADDLE_ZONE_4 equ 12    ; Next 12 pixels belong to zone 4
PADDLE_ZONE_5 equ 8     ; Next 8 pixels belong to zone 5
; Zones are used to determine the speed adjustments when bouncing off the paddle

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

    game_over_msg   db "OH NO! You've used up all of your lives :(", 0ah, 0dh, 24h

    ; Levels
    ; Note: Should be kept in continuous memory!
    ; Every byte in memory indicates a color for a block, ALL blocks must be given a color!
    level_1 db BLOCKS_COLUMNS dup (6)
            db BLOCKS_COLUMNS dup (5)
            db BLOCKS_COLUMNS dup (4)
            db BLOCKS_COLUMNS dup (3)
            db BLOCKS_COLUMNS dup (2)
            db BLOCKS_COLUMNS dup (1)

    level_end db 0 ; Take the offset of this pointer and you get the end of all levels

;=============================================================================
; Uninitialized DATA
;=============================================================================
UDATASEG
    blocks      db BLOCKS_AMOUNT dup (?)
    ball_x      dd ?    ; x position of the ball (as dword because will be passed as argument via stack)
    ball_y      dd ?    ; y position of the ball
    paddle_x    dd ?    ; x position of the paddle
    ; Ball speeds
    ball_x_speed dd ?   ; Negative value: move left with that much pixels, positive value: move right with that much pixels
    ball_y_speed dd ?   ; Negative value: move up with that much pixels, positive value: move down with that much pixels