;==================
; Sprites
;==================
; Always use multiples of 4 as width! (Faster drawing)

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

; Life sprite
_life   dw LIFE_W, LIFE_H
        db 0, 1, 1, 0, 0, 1, 1, 0
        db LIFE_W * 4 dup (1)
        db 0, 1, 1, 1, 1, 1, 1, 0
        db 0, 0, 1, 1, 1, 1, 0, 0
        db 0, 0, 0, 1, 1, 0, 0, 0

; Score text sprite
_score  dw SCORE_W, SCORE_H
        db 0, 7, 7, 7, 0, 0, 7, 7, 0, 0, 0, 7, 7, 0, 0, 7, 7, 7, 0, 0, 0, 7, 7, 7
        db 7, 0, 0, 0, 0, 7, 0, 0, 7, 0, 7, 0, 0, 7, 0, 7, 0, 0, 7, 0, 7, 0, 0, 0
        db 0, 7, 7, 0, 0, 7, 0, 0, 0, 0, 7, 0, 0, 7, 0, 7, 7, 7, 0, 0, 7, 7, 7, 0
        db 0, 0, 0, 7, 0, 7, 0, 0, 7, 0, 7, 0, 0, 7, 0, 7, 0, 0, 7, 0, 7, 0, 0, 0
        db 7, 7, 7, 0, 0, 0, 7, 7, 0, 0, 0, 7, 7, 0, 0, 7, 0, 0, 7, 0, 0, 7, 7, 7

; Digit sprites
_digits dw DIGIT_W, DIGIT_H ; 0
        db 0, 7, 7, 0
        db 7, 0, 0, 7
        db 7, 0, 0, 7
        db 7, 0, 0, 7
        db 0, 7, 7, 0

        dw DIGIT_W, DIGIT_H ; 1
        db 0, 7, 7, 0
        db 7, 0, 7, 0
        db 0, 0, 7, 0
        db 0, 0, 7, 0
        db 0, 7, 7, 7

        dw DIGIT_W, DIGIT_H ; 2
        db 0, 7, 7, 0
        db 7, 0, 0, 7
        db 0, 0, 7, 0
        db 0, 7, 0, 0
        db 7, 7, 7, 7

        dw DIGIT_W, DIGIT_H ; 3
        db 0, 7, 7, 0
        db 7, 0, 0, 7
        db 0, 0, 7, 0
        db 7, 0, 0, 7
        db 0, 7, 7, 0

        dw DIGIT_W, DIGIT_H ; 4
        db 7, 0, 7, 0
        db 7, 0, 7, 0
        db 7, 7, 7, 7
        db 0, 0, 7, 0
        db 0, 0, 7, 0

        dw DIGIT_W, DIGIT_H ; 5
        db 7, 7, 7, 7
        db 7, 0, 0, 0
        db 7, 7, 7, 0
        db 0, 0, 0, 7
        db 7, 7, 7, 0

        dw DIGIT_W, DIGIT_H ; 6
        db 0, 7, 7, 7
        db 7, 0, 0, 0
        db 7, 7, 7, 0
        db 7, 0, 0, 7
        db 0, 7, 7, 0

        dw DIGIT_W, DIGIT_H ; 7
        db 0, 7, 7, 7
        db 0, 0, 0, 7
        db 0, 0, 0, 7
        db 0, 0, 0, 7
        db 0, 0, 0, 7

        dw DIGIT_W, DIGIT_H ; 8
        db 0, 7, 7, 0
        db 7, 0, 0, 7
        db 0, 7, 7, 0
        db 7, 0, 0, 7
        db 0, 7, 7, 0

        dw DIGIT_W, DIGIT_H ; 9
        db 0, 7, 7, 0
        db 7, 0, 0, 7
        db 0, 7, 7, 7
        db 0, 0, 0, 7
        db 7, 7, 7, 0

; To clear the ball
_ball_clear dw BALL_W, BALL_H
            db BALL_W * BALL_H dup (0)

; To clear the paddle
_paddle_clear   dw PADDLE_W, PADDLE_H
                db PADDLE_W * PADDLE_H dup (0)