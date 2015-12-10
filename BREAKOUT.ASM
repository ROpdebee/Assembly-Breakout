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
    call Game                       ; and start the game loop
    jmp @@gameStart                 ; Go back to the start window when GameLoop returned (game is over)

@@quit:                             ; Quit game
    mov eax, 4c00h                  ; AH = 4Ch - Exit To DOS
    int 21h                         ; DOS INT 21h


; Print welcome message and instructions and wait for keyboard input
PROC GameEntry
    ARG RETURNS eax            ; May not be an optimal solution but Turbo Assembler complains if there is a RETURNS statement without ARG
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

; Heart of the game
; Set of loops that power the game
PROC Game
    USES eax
    LOCAL @@lives:dword, @@level:dword, @@remaining_blocks:dword, @@score:dword

    ; Set the lives to the starting amount
    mov [@@lives], STARTING_LIVES

    ; Start with the first level
    mov [@@level], offset level_1

    ; Score is initialize zero
    mov [@@score], 0

@@levelLoop:
    call InitializeWorld, [@@level] ; First initialize the world
    ; Amount of blocks now in EAX
    mov [@@remaining_blocks], eax

@@lifeLoop:
    call ResetBallAndPaddle         ; Reset the ball and paddle to their default positions

@@refresh:
    ; Update graphics first
    call ClearTopRows               ; Clear the top rows that are used to store information because all this information is to be redrawn
    call DrawLives, [@@lives]
    call DrawScore, [@@score]
    call DrawPaddle, [paddle_x], PADDLE_Y
    call DrawBall, [ball_x], [ball_y]
    call UpdateScreen

    ; Then remove the ball and paddle because we're only selectively redrawing the changed parts and their coordinates are about to change
    call ClearBallAndPaddle, [ball_x], [ball_y], [paddle_x], PADDLE_Y
    call DrawChangedBlocks          ; Redraw the changed blocks, wait until after the ball has been cleared from the screen to avoid graphic glitches (dents in the blocks etc)

    ; Process user input and move paddle
    call ProcessInput
    jz short @@gameOver             ; If zero flag has been set, we should quit the game

    ; Move the ball
    call MoveBall
    jz @@lifeLost                   ; If zero flag has been set, then a life has been lost

    ; Check for collisions
    call CheckCollisions
    add [@@score], eax              ; Calculate the new score
    sub [@@remaining_blocks], eax
    jz @@levelWon                   ; If there are no remaining blocks, the player has won the level

    ; Start over
    jmp @@refresh

@@lifeLost:                         ; The player has lost a life
    ; Remove the ball and paddle because they're potentially going to be reset
    call ClearBallAndPaddle, [ball_x], [ball_y], [paddle_x], PADDLE_Y
    ; Decrease the lives
    dec [@@lives]
    jnz @@lifeLoop                  ; Restart the level, but keep the blocks intact
    ; Otherwise when there are zero lives left, reset the video mode and print a message indicating that the game has been lost
    call ResetVideo
    mov ah, 09h                     ; DOS - Print String
    mov edx, offset no_lives_msg
    int 21h                         ; DOS call will print the string
    ret                             ; Exit game loop

@@levelWon:
    add [@@level], BLOCKS_AMOUNT    ; Level ptr now points to the next level
    cmp [@@level], offset level_end
    jne @@levelLoop                 ; If the game hasn't gone through all the levels, load in the new level
    ; All levels have been won
    call ResetVideo
    mov ah, 09h                     ; DOS print string
    mov edx, offset game_won_msg
    int 21h                         ; DOS call
    ret                             ; Exit game loop

@@gameOver:
    call ResetVideo
    ret
ENDP Game

; Initializes the game world and draws the starting environment
; Parameters: level (dword): Pointer to the level that should be loaded
; Returns the total amount of blocks in EAX
PROC InitializeWorld
    ARG @@level:dword RETURNS eax
    USES ecx, esi, edi

    ; Load the level and draw the blocks
    mov esi, [@@level]
    mov edi, offset blocks
    xor ebx, ebx                    ; Clear out ebx, later used for storing color
    xor ecx, ecx                    ; Clear out ecx, used as counter
    xor eax, eax                    ; Clear out eax, used to count blocks

@@blockLoop:
    movsb                           ; Move the current block from this level into blocks
    mov bl, [esi-1]                 ; Get the color of the block, put in BL. Color is 1 byte. Keep in mind that ESI has changed
    cmp bl, 0
    jz @@blackBlock                 ; Not a block if it's coloured black, so bypass the next lines
    add eax, ebx                    ; Add to block count, we pass the colour but this colour indicates how long the block will last
    call DrawBlockNumber, ecx, ebx  ; Have to pass the whole EBX register via stack, hence EBX needed to be cleared before storing the color in BL
@@blackBlock:
    inc ecx
    cmp ecx, BLOCKS_AMOUNT
    jne @@blockLoop                 ; If ECX is not yet at the end, do another block

    ret
ENDP InitializeWorld

; Convert a block number to a valid coordinate and draw a block on this coordinate
; Parameters: block: A block number
;             color: The block's color
; Returns: none
PROC DrawBlockNumber
    ARG @@block:dword, @@color:dword
    USES ebx, eax, edx

    mov eax, [@@block]              ; Argument block in eax
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

    ; Draw the block with these coordinates and the color
    call DrawBlock, edx, eax, [@@color]

    ret
ENDP DrawBlockNumber

; Draws all the valid block numbers in blocks_changed
PROC DrawChangedBlocks
    USES eax, ecx, esi, ebx, edx

    xor eax, eax                    ; Clear out eax
    xor edx, edx                    ; To store color
    mov ecx, BLOCKS_MAX_CHANGED
    mov esi, offset blocks_changed
    mov ebx, offset blocks
@@drawLoop:
    lodsb                           ; Load a block number into AL
    cmp al, 0
    jl @@end                        ; If the block number is invalid, we already got to the end so stop
    mov dl, [ebx + eax]             ; Store color in DL
    call DrawBlockNumber, eax, edx  ; Pass whole EDX because it expects a dword (rest of EDX is already cleared out)
    mov [byte ptr esi-1], -1        ; Overwrite the previously read in entry (we could do this faster by just moving a dword after the loop but BLOCKS_MAX_CHANGED may change some day)
    dec ecx
    jnz @@drawLoop
@@end:
    ret
ENDP DrawChangedBlocks

; Draw the lives
PROC DrawLives
    ARG @@lives:dword
    USES ecx, edi

    mov ecx, [@@lives]
    mov edi, LIVES_STARTING_X
@@drawLife:                         ; As long as there are lives to draw, draw one and move the x position
    call DrawLife, edi, LIVES_STARTING_Y
    add edi, LIFE_W + LIVES_SEPARATOR
    dec ecx
    jnz @@drawLife
    ret
ENDP DrawLives

; Draw the score from right to left
PROC DrawScore
    ARG @@score:dword
    USES eax, edi, ebx, edx

    ; Adapt the print numbers exercise to draw the numbers to the screen
    ; Don't check for signed numbers, definitely unsigned.
    mov eax, [@@score]
    mov edi, SCORE_RIGHT_X
    mov ebx, 10                     ; Divide by 10 to get the first digit
@@digit:
    xor edx, edx                    ; Clear out EDX for division
    div ebx                         ; Remainder in EDX, quotient in EAX
    call DrawDigit, edx, edi, SCORE_Y
    sub edi, DIGIT_W + 1            ; Position for next element (include one separating pixel)
    cmp eax, 0
    jnz @@digit

    ; All digits have been drawn, we still need to draw the text
    sub edi, SCORE_W                ; Position to draw the text
    call DrawScoreText, edi, SCORE_Y

    ret
ENDP DrawScore

PROC ResetBallAndPaddle

    ; Move ball and paddle to default positions
    mov [ball_x], BALL_START_X
    mov [ball_y], BALL_START_Y
    mov [paddle_x], PADDLE_START_X

    ; Reset the speeds
    mov [ball_x_speed], BALL_START_X_SPEED
    mov [ball_y_speed], BALL_START_Y_SPEED

    ret
ENDP ResetBallAndPaddle

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

; Move the ball
; Sets ZF when the ball has fallen off the bottom of the screen
PROC MoveBall
    USES eax, ebx

    ; Adjust the coordinates
    mov eax, [ball_x]
    mov ebx, [ball_y]
    add eax, [ball_x_speed]
    add ebx, [ball_y_speed]

    ; Check the new coordinates and adjust them if necessary
    ; First check the y position
    jns @@checkBottom               ; If sign bit is not set, y doesn't fall off the top of the screen, so proceed checking and skip the adjustment
    mov ebx, 0                      ; Otherwise adjust the y position
    jmp @@checkX                    ; And check the x position: we know it can't fall off the screen at the bottom because it already did at the top

@@checkBottom:
    cmp ebx, BALL_MAX_Y             ; Now check if ball has fallen off the bottom
    jg @@ballMissed                 ; If the paddle has missed the ball, indicate this

@@checkX:
    cmp eax, 0                      ; Now check if x has fallen off the left
    jge @@checkRight                ; If ball has not fallen off at the left, make sure it doesn't fall off at the right
    mov eax, 0                      ; Otherwise normalize the x coordinate to the leftmost position
    jmp @@update                    ; Jump to the end, as it can't fall off the right anymore

@@checkRight:
    cmp eax, BALL_MAX_X             ; Check if x falls off the right
    jle @@update                    ; If ball doesn't fall off at the right either, just jump to the end
    mov eax, BALL_MAX_X             ; Otherwise we have to normalize the x coordinate
    jmp @@update

@@ballMissed:
    ; We have to signal that the ball has fallen off the bottom of the bottom by setting the ZF
    lahf                            ; Load the flags into AH
    or ah, 40h                      ; Set the ZF
    sahf                            ; Store the flags
    ret                             ; Return immediately

@@update:
    ; Update the coordinates
    mov [ball_x], eax
    mov [ball_y], ebx
    ; We should return to the caller but we have to make sure that ZF is not set
    lahf
    and ah, 0bfh                    ; Unset ZF
    sahf
    ret
ENDP MoveBall

; Check for collisions
; Returns amount of blocks hit in EAX
PROC CheckCollisions
    ARG RETURNS eax
    USES ebx, ecx, esi

    xor eax, eax                    ; Clear out eax for possible counting

    mov ebx, [ball_y]               ; Put the top y position of the ball in ebx
    mov ecx, ebx
    add ecx, BALL_H - 1             ; Put the bottom y position of the ball in ecx

    ; Determine how we should check for collisions based on y position
    cmp ebx, PADDLE_BOTTOM          ; Ball overshoots the paddle if its top is underneath the paddle
    jg @@onlyX                      ; If the ball has overshot the paddle, we only need to check the x position to make sure it bounces off the sides
    cmp ecx, PADDLE_Y - 1           ; Now compare the bottom of the ball to the top of the paddle (check one pixel above because we don't want the ball to go 'in' the paddle)
    jge @@checkPaddle               ; The ball possibly collides with the paddle, check this
    ; Ball is definitely above the paddle
    cmp ebx, BLOCKS_BOTTOM          ; Compare top of ball against bottom of blocks
    jg @@onlyX                      ; If the ball is underneath the lowest point of the blocks, we only have to check the sides
    cmp ecx, BLOCKS_TOP             ; Compare bottom of ball against the highest point of the blocks
    jge @@checkBlock                ; Check if the ball collides with a block if it is situated somewhere amongst the blocks
    cmp ebx, 0                      ; Compare the top of the ball against the top of the screen
    je short @@bounceTop            ; If the ball hits the top, then bounce if off (SHORT jump because Turbo Assembler complains otherwise)
    ; If we reach this, the ball is situated between the top of the screen and the top of the blocks, so we only need to check the x position -> fall through

;*******
; Walls
;*******
@@onlyX:
    ; Check if it bounces against any of the vertical sides and bounce accordingly
    mov ebx, [ball_x]               ; Set left position of the ball in ebx
    cmp ebx, 0
    je @@bounceX                    ; If it bounces against the left side, change the trajectory accordingly
    cmp ebx, BALL_MAX_X
    je @@bounceX                    ; If it bounces against the right side, change the trajectory accordingly
    jmp short @@end                       ; If it doesn't collide with anything, just jump to the end

@@bounceX:
    neg [ball_x_speed]              ; Just invert the x speed, leave the y speed intact
    jmp @@end                       ; Jump to the end

;********
; Paddle
;********
@@checkPaddle:
    ; We need to check if it actually collides with the paddle 
    mov ecx, [ball_x]
    add ecx, BALL_W - 1
    sub ecx, [paddle_x]
    ; ECX is now the difference in pixels between the rightmost x of the ball and the x coordinate of the paddle,
    ; this allows us to work more with constants instead of getting values from memory all the time

    ; Check if ball lies in front of the paddle
    js @@onlyX                      ; If sign bit is set from the previous instruction, the difference is negative and the ball lies completely in front of the paddle
    ; Check if ball lies behind the paddle
    cmp ecx, PADDLE_W + BALL_W
    jge @@onlyX                     ; If it does, just check if it doesn't bounce against the walls
    ; We know for sure that the ball lies somewhere on the paddle if we reach this point

    push ebx                        ; We're going to use EBX later, so save it on the stack
    mov esi, offset zone_speeds     ; ESI now contains the address of the first zone speed
    mov ebx, offset zone_limits     ; Load the address of the first zone limit into EBX

    ; Now find the zone
@@findZone:
    cmp ecx, [ebx]                  ; See if ball lies within the limits pointed to by ebx
    jl @@zoneFound
    ; If we reach this point, it doesn't
    add esi, 4                      ; Make the speed pointer point 4 bytes further, to the next zone speed
    add ebx, 4                      ; Make the limit pointer point 4 bytes further as well
    ; Since the limits and speeds are in continuous memory, we can exploit this to see if we've checked all limits
    cmp ebx, offset zone_speeds     ; Compare the pointer to the limit to the address of the first zone speed
    jne @@findZone                  ; If they're not equal, we haven't reached the end yet
    ; We've tested all zones but the ball fell within none of the limits, but it hits the paddle, hence it belongs to the last zone, to which the speed already points
    ; We can just fall through

    ; We found the zone and ESI points to the correct speed adjustment
@@zoneFound:
    mov ecx, [esi]                  ; Get the zone speed from memory, we have to do this explicitely because memory-to-memory mov's are not supported
    mov [ball_x_speed], ecx         ; Store the new x speed
    pop ebx                         ; Remember to restore the previously pushed y position of the ball
    ; We still need to potentially change the y trajectory
    ; If the top of the ball has gone beyond the top of the paddle (e.g. at the sides) then the trajectory shouldn't be adjusted because the ball can't go back up
    cmp ebx, PADDLE_Y               ; Compare ebx to the top position of the paddle
    jge @@end
    ; Ball is still (partially) above the paddle, so bounce back up
    mov [ball_y_speed], -1
    jmp @@end

;***************
; Top of screen
;***************
@@bounceTop:
    ; We know it bounces against the top, so invert the y speed
    mov [ball_y_speed], 1           ; y speed can only be 1 or -1 so we can just adjust it instead of negating
    jmp @@onlyX                     ; Might be in a corner, then it'd collide with the side as well and the x speed would need adjustment

;********
; Blocks
;********
@@checkBlock:
    call BlockCollision             ; Call to other procedure to try to keep things neat
    jmp @@onlyX                     ; Check for collisions with walls as well

@@end:
    ret
ENDP CheckCollisions

; Check for collisions with blocks
; Returns amount of blocks hit in EAX
; Note: Don't assume anything about the current state of registers!
PROC BlockCollision
    ARG RETURNS eax
    USES ebx, ecx, edx, edi

    ; We still have to manually do the BP manipulation because the IDEAL syntax doesn't do this when there are no arguments or local variables
    push ebp
    mov ebp, esp

    xor dl, dl                      ; Clear out DL as it'll be used to indicate which corners have hit a block

    ; Get a block number for each 'corner' of the ball, and push this block number on the stack if it's valid
    ; EBP and ESP point to the same address at this moment, so we can use EBP to see if we've processed all blocks later on
    ; First get the block number for the top left corner
    mov eax, [ball_x]
    mov ecx, [ball_y]
    call GetBlockNumber, eax, ecx   ; Block number for top left corner now in EBX
    cmp ebx, 0
    js @@topRight                   ; If block number is invalid, don't save it
    ; Check the color of the block
    cmp [byte ptr offset blocks + ebx], 0
    jz @@topRight                   ; If it's a black block, the corner hasn't actually hit anything so ignore it
    or dl, 1                        ; Indicate that this corner has hit a block
    push ebx                        ; Save the block number on the stack
    ; Now check the top right corner
@@topRight:
    add eax, BALL_W - 1
    call GetBlockNumber, eax, ecx   ; Block number for top right corner now in EBX
    cmp ebx, 0
    js @@bottomRight
    cmp [byte ptr offset blocks + ebx], 0
    jz @@bottomRight
    or dl, 2
    push ebx
    ; Bottom right corner
@@bottomRight:
    add ecx, BALL_H - 1
    call GetBlockNumber, eax, ecx
    cmp ebx, 0
    js @@bottomLeft
    cmp [byte ptr offset blocks + ebx], 0
    jz @@bottomLeft
    or dl, 4
    push ebx
    ; Bottom left corner
@@bottomLeft:
    sub eax, BALL_W - 1
    call GetBlockNumber, eax, ecx
    cmp ebx, 0
    js @@cornersDone                ; If block number is invalid, proceed to checking the others
    cmp [byte ptr offset blocks + ebx], 0
    jz @@cornersDone
    or dl, 8
    push ebx                        ; If it's not a black block, push it

@@cornersDone:
    ; All valid blocks on the stack, keep in mind that some block numbers may be repeated
    xor eax, eax                    ; Clear out eax for counting
    mov edi, offset blocks_changed  ; To save the block numbers of the changed blocks
@@processBlocks:
    cmp esp, ebp
    je @@done                       ; If we've reached the bottom of this activation record's stack, all blocks have been processed
    pop ebx                         ; Pop a block number into EBX
    ; Still need to check if this block number doesn't occur multiple times
    mov ecx, esp                    ; Move the stack pointer into ecx
@@checkDuplicates:
    cmp ecx, ebp
    je @@noDuplicates               ; If we're at the bottom of the stack, there haven't been any duplicates
    cmp ebx, [dword ptr ecx]        ; Compare the current block number against the one we're considering in the stack
    je @@processBlocks              ; If they're equal, just skip this block number, we'll process it when we reach the duplicate
    ; Otherwise, these are not duplicates, but there may be another block number that is, so keep searching
    add ecx, 4                      ; We move the copy of the stack pointer 4 bytes up, so that it points to the previous stack element (stack grows down)
    jmp @@checkDuplicates           ; Check the next element

@@noDuplicates:                     ; We haven't found any duplicated block number for the one we're considering now, so process this block number
    ; Decrement the value of the block
    dec [byte ptr offset blocks + ebx]
    mov [edi], bl                   ; Indicate that the block has been changed
    inc edi
    inc eax                         ; Increase eax to display that we've hit a block
    jmp @@processBlocks             ; Process another block

@@done:
    VERSION m510                    ; Temporarily switch to MASM 5.1 so we can use anonymous labels
    ; We still need to adjust the trajectory of the ball. Recall that DL was adjusted to indicate which corners hit a block
    ; Based on DL we can determine which speeds should be negated. There should be a better way to do this instead of turning bits off and then comparing...
    mov dh, dl                      ; Copy DL to DH because it is going to be modified
    and dl, 0ch
    cmp dl, 0ch
    je short @@verticalBounce       ; Bottom of the ball has hit something
    mov dl, dh
    and dl, 3h
    cmp dl, 3h
    je short @@verticalBounce       ; Top of the ball has hit something
    ; Neither the top nor the bottom has hit anything, but the sides may have hit something

@@horizontalCheck:
    mov dl, dh
    and dl, 9h
    cmp dl, 9h
    je short @@horizontalBounce     ; Left side has hit something
    mov dl, dh
    and dl, 6h
    cmp dl, 6h
    je short @@horizontalBounce     ; Right side has hit something
    cmp dh, 0
    jp short @@end
    ; Only one corner has hit something, so the ball has hit a block's corner
    ; Depending on which corner has hit the block, we need to change the trajectory. The direction from which the ball comes doesn't matter!
    shr dh, 1
    jnz @F
    ; Top left corner has hit
    mov [ball_y_speed], 1
    mov [ball_x_speed], 1           ; To be completely correct, we should invert this value only if it's signed, but that'd take too many instructions for a very rare case
    jmp @@end
@@: shr dh, 1
    jnz @F
    ; Top right corner has hit
    mov [ball_y_speed], 1
    mov [ball_x_speed], -1
    jmp @@end
@@: mov [ball_y_speed], -1          ; All other possibilities bounce back up, saves us exactly one instruction
    shr dh, 1
    jnz @F
    ; Bottom right corner has hit
    mov [ball_x_speed], -1
    jmp @@end
    ; In any other case (which should by now be only one), the bottom left corner has hit
@@: mov [ball_x_speed], 1
    jmp @@end

@@verticalBounce:
    neg [ball_y_speed]              ; Invert the ball's y trajectory
    jmp @@horizontalCheck           ; Ball possibly also hits something with the sides

@@horizontalBounce:
    neg [ball_x_speed]              ; Invert the ball's x trajectory
    ; Fall through to the end

@@end:
    ; Clean up the stack and base pointers as we've adjusted them at the beginning of the procedure
    mov esp, ebp
    pop ebp
    ret
ENDP BlockCollision

; Get the block number corresponding to the argument coordinates
; Parameters: x, y (dwords)
; Returns block number in ebx. Negative block number indicates that there is no block on this coordinate
PROC GetBlockNumber
    ARG @@x:dword, @@y:dword RETURNS ebx
    USES eax, ecx

    xor ebx, ebx                    ; Clear out EBX

    ; First calculate the column number
    mov eax, [@@x]                  ; Store dividend in ax. x is definitely smaller than SCREEN_WIDTH so it'll fit, but it's passed as a double word
    mov cl, BLOCK_W                 ; Divisor is the block width
    div cl                          ; We can use div, because we know dividend is not negative. Column number will now be AL, remainder in AH is of no importance
    mov bl, al                      ; Move column number into BL, so that EBX is the column number

    ; Now calculate the row number
    mov eax, [@@y]                  ; Store dividend into ax
    sub eax, TOP_SKIP_ROWS*BLOCK_H  ; Transform y so that the first row would start at 0, ignoring the top rows that have been skipped
    js @@invalid                    ; If y is now negative, there will definitely be no block because the coordinate is situated in the top rows
    mov cl, BLOCK_H                 ; Divisor is the block height
    div cl                          ; Divide word in AX by byte in DL, so that row number is in AL and remainder in AH
    cmp al, BLOCKS_ROWS             ; Check if it's a valid row
    jge @@invalid
    xor ah, ah                      ; Clear out the remainder, so now eax contains the row number
    imul eax, BLOCKS_COLUMNS        ; Transform the row number to the block number of its first block
    add ebx, eax                    ; Add this block number to the column number previously in ebx
    ; EBX now contains the block number
    ret                             ; Return to caller

@@invalid:
    mov ebx, -1                     ; Store -1 into EBX to indicate that it's an invalid block number
    ret
ENDP GetBlockNumber



;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±?
; STACK
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±?
STACK 1000h

END start

