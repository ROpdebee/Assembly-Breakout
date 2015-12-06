; Procedures
GLOBAL 	InitializeVideo:PROC, \
        ResetVideo:PROC, \
        UpdateScreen:PROC, \
        RenderBlock:PROC, \
        RenderBall:PROC, \
        RenderPaddle:PROC, \
        ClearBallAndPaddle:PROC
        
; Constants
SCREEN_WIDTH equ 320
SCREEN_HEIGHT equ 200

BALL_W equ 8
BALL_H equ 8

PADDLE_W equ 64
PADDLE_H equ 8

BLOCK_W equ 32  ; Width of a block
BLOCK_H equ 8   ; Height of a block