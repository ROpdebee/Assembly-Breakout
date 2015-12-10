; Procedures
GLOBAL 	InitializeVideo:PROC, \
        ResetVideo:PROC, \
        UpdateScreen:PROC, \
        DrawBlock:PROC, \
        DrawBall:PROC, \
        DrawPaddle:PROC, \
        ClearBallAndPaddle:PROC, \
        DrawLife:PROC, \
        ClearTopRows:PROC, \
        DrawDigit:PROC, \
        DrawScoreText:PROC
        
; Constants shared between GUI.asm and BREAKOUT.asm
SCREEN_WIDTH equ 320
SCREEN_HEIGHT equ 200

BALL_W equ 8
BALL_H equ 8

PADDLE_W equ 64
PADDLE_H equ 8

BLOCK_W equ 32  ; Width of a block
BLOCK_H equ 8   ; Height of a block

LIFE_H equ 8
LIFE_W equ 8

DIGIT_W equ 4
DIGIT_H equ 5

SCORE_H equ 5
SCORE_W equ 24

TOP_SKIP_ROWS equ 3 ; Top rows to skip