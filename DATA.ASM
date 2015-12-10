;=============================================================================
; Breakout Data and constants
;
; Only holds data for breakout.asm, other data may be defined in other files
;=============================================================================

; Block grid constants
BLOCKS_COLUMNS equ 10
BLOCKS_ROWS equ 8
BLOCKS_AMOUNT equ BLOCKS_COLUMNS * BLOCKS_ROWS
BLOCKS_BOTTOM equ (BLOCKS_ROWS + TOP_SKIP_ROWS) * BLOCK_H - 1
BLOCKS_TOP equ TOP_SKIP_ROWS * BLOCK_H
BLOCKS_MAX_CHANGED equ 4    ; There will never be more than 4 blocks changed in one generation (probably never more than two but you never know)

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

; Lives constants
LIVES_STARTING_X equ 1   ; Pixel where the lives are drawn
LIVES_STARTING_Y equ 1
LIVES_SEPARATOR equ 1
STARTING_LIVES equ 5     ; Amount of lives the player starts with

; Score constants
SCORE_RIGHT_X equ SCREEN_WIDTH - DIGIT_W - 1
SCORE_Y equ 1

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

    no_lives_msg    db "OH NO! You've used up all of your lives :(", 0ah, 0dh, 24h

    game_won_msg    db "SUCCESS! You've reached the end of the game!", 0ah, 0dh, 24h

    ; Zones are used to determine the speed adjustments when bouncing off the paddle
    zone_limits dd 8, 20, 36, 52, 60    ; Array of limits of each zone for the rightmost position of the ball, from left to right
    zone_speeds dd -3, -2, -1, 1, 2, 3  ; Array of speeds corresponding to each zone, as dwords because they are to be assigned to other dwords
    ; Any ball that falls outside these zones but still hits the paddle belongs to zone 6, so the mismatch in array elements is intentional

    ; Levels
    ; Note: Should be kept in continuous memory!
    ; Every byte in memory indicates a color for a block, ALL blocks must be given a color!
    level_1 db BLOCKS_COLUMNS * 2 dup (3)
            db BLOCKS_COLUMNS * 2 dup (2)
            db BLOCKS_COLUMNS * 2 dup (1)
            db BLOCKS_COLUMNS * 2 dup (0) ; Last two lines blank

    level_2 db 0, 1, 1, 1, 0, 0, 2, 2, 2, 0
            db 0, 1, 0, 1, 0, 0, 2, 0, 2, 0
            db 0, 1, 0, 1, 0, 0, 0, 0, 2, 0
            db 0, 1, 0, 1, 0, 0, 0, 2, 0, 0
            db 0, 1, 0, 1, 0, 0, 2, 0, 0, 0
            db 0, 1, 1, 1, 0, 0, 2, 2, 2, 0
            db BLOCKS_COLUMNS * 2 dup (0)

    level_3 db 0, 1, 1, 1, 1, 1, 1, 1, 1, 0
            db 0, 1, 0, 0, 0, 0, 0, 0, 1, 0
            db 0, 1, 0, 2, 2, 2, 2, 0, 1, 0
            db 0, 1, 0, 2, 0, 0, 2, 0, 1, 0
            db 0, 1, 0, 2, 0, 0, 2, 0, 1, 0
            db 0, 1, 0, 2, 2, 2, 2, 0, 1, 0
            db 0, 1, 0, 0, 0, 0, 0, 0, 1, 0
            db 0, 1, 1, 1, 1, 1, 1, 1, 1, 0

    level_4 db 1, 0, 2, 2, 0, 0, 2, 2, 0, 1
            db 1, 0, 2, 2, 0, 0, 2, 2, 0, 1
            db 1, 0, 0, 0, 0, 0, 0, 0, 0, 1
            db 1, 0, 3, 3, 0, 0, 3, 3, 0, 1
            db 1, 0, 3, 3, 0, 0, 3, 3, 0, 1
            db 1, 0, 0, 0, 0, 0, 0, 0, 0, 1
            db 1, 0, 2, 2, 0, 0, 2, 2, 0, 1
            db 1, 0, 2, 2, 0, 0, 2, 2, 0, 1

    level_5 db 0, 0, 1, 1, 1, 1, 1, 1, 0, 0
            db 0, 2, 0, 0, 0, 0, 0, 0, 2, 0
            db 1, 2, 0, 3, 3, 3, 3, 0, 2, 1
            db 1, 0, 0, 3, 4, 4, 3, 0, 0, 1
            db 1, 0, 0, 3, 4, 4, 3, 0, 0, 1
            db 1, 2, 0, 3, 3, 3, 3, 0, 2, 1
            db 0, 2, 0, 0, 0, 0, 0, 0, 2, 0
            db 0, 0, 1, 1, 1, 1, 1, 1, 0, 0

    ; Spaceship/rocket
    level_6 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            db 0, 5, 5, 5, 0, 0, 0, 0, 0, 0
            db 0, 0, 5, 5, 5, 5, 5, 5, 0, 0
            db 0, 2, 5, 5, 5, 5, 5, 5, 5, 0
            db 2, 1, 5, 5, 5, 0, 5, 0, 5, 5
            db 0, 2, 5, 5, 5, 5, 5, 5, 5, 0
            db 0, 0, 5, 5, 5, 5, 5, 5, 0, 0
            db 0, 5, 5, 5, 0, 0, 0, 0, 0, 0

    level_7 db 6, 0, 6, 0, 6, 0, 6, 0, 6, 0
            db 0, 5, 0, 5, 0, 5, 0, 5, 0, 5
            db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            db 0, 4, 0, 4, 0, 4, 0, 4, 0, 4
            db 3, 0, 3, 0, 3, 0, 3, 0, 3, 0
            db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            db 2, 0, 2, 0, 2, 0, 2, 0, 2, 0
            db 0, 1, 0, 1, 0, 1, 0, 1, 0, 1

    ; Very standard end level but I personally find it very difficult
    level_8 db BLOCKS_COLUMNS dup (6)
            db BLOCKS_COLUMNS dup (5)
            db BLOCKS_COLUMNS dup (4)
            db BLOCKS_COLUMNS dup (3)
            db BLOCKS_COLUMNS dup (2)
            db BLOCKS_COLUMNS dup (1)
            db BLOCKS_COLUMNS * 2 dup (0)

    level_end db 0 ; Take the offset of this pointer and you get the end of all levels

    blocks_changed  db BLOCKS_MAX_CHANGED dup (-1)   ; Array of block numbers that have changed in the last generation

;=============================================================================
; Uninitialized DATA
;=============================================================================
UDATASEG
    blocks          db BLOCKS_AMOUNT dup (?)
    ball_x          dd ?    ; x position of the ball (as dword because will be passed as argument via stack)
    ball_y          dd ?    ; y position of the ball
    paddle_x        dd ?    ; x position of the paddle
    ; Ball speeds
    ball_x_speed    dd ?    ; Negative value: move left with that much pixels, positive value: move right with that much pixels
    ball_y_speed    dd ?    ; Negative value: move up with that much pixels, positive value: move down with that much pixels