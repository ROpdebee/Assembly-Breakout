;=============================================================================
; Breakout Sound Handler using PC Speaker
;
; Based on: http://www.fysnet.net/snd.htm
; and: http://fly.srk.fer.hr/GDM/articles/sndmus/speaker1.html
;=============================================================================

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "sound.inc"

;=============================================================================
; DATA
;=============================================================================
DATASEG
    sound_to_play dw 0, 0   ; Frequency and duration of the current sound to play
;=============================================================================
; CODE
;=============================================================================
CODESEG

; Initialize everything necessary for the sound handler
PROC InitializeSound
    USES eax, edx

    ; Prepare the timer so we can write the frequencies to it
    ; We need channel 2 of the programmable interval timer, which is connected to the speaker
    mov dx, 43h                     ; Timer Mode/Command port
    mov al, 0B6h                    ; Ch 2, access mode lo/hi byte
    out dx, al

    ret
ENDP InitializeSound

; Sound handler
; Will check the sound to play, and will disable the PC Speaker if the sound should stop
PROC SoundHandler
    cmp [word ptr offset sound_to_play], 0
    jz @@end                        ; If there's no frequency set, there's no sound currently playing
    dec [word ptr offset sound_to_play + 2]  ; Decrement the sound duration
    jnz @@end
    call StopSound                  ; Disable the PC Speaker if the sound should stop
@@end:    
    ret
ENDP SoundHandler

; Deactivate the PC speaker
PROC StopSound
    USES eax, edx

    mov dx, 61h                     ; System control port
    in al, dx                       ; Read in the data
    and al, 0FCh                    ; Turn off bit 1 and 0 -> disable speaker data and timer 2 gate to speaker
    out dx, al                      ; Write that back to the port
    ret
ENDP StopSound

; Set a new sound to play and activate the PC speaker
; Parameter: sound_ptr (dword): A pointer to a sound to play
; This sound will be interpreted as two words: the frequency followed by the duration in number of game generations
PROC PlaySound
    ARG @@sound_ptr:dword
    USES esi, edi, eax, edx

    mov esi, [@@sound_ptr]
    mov edi, offset sound_to_play

    lodsw                           ; First load the frequency into AX
    stosw                           ; Store the frequency in sound_to_play
    mov dx, 42h                     ; Timer channel 2 data port
    out dx, al                      ; Output the lobyte to the timer
    xchg al, ah                     ; Now swap AL and AH
    out dx, al                      ; Output the hibyte to the timer
    ; Timer will now 'tick' according to the frequency we just read in
    movsw                           ; Copy the duration from the sound to the internal variable
    ; Note that we should still enable the speaker, otherwise it won't produce any sound!
    mov dx, 61h                     ; System control port
    in al, dx                       ; Read in the data
    or al, 3h                       ; Turn on bit 0 and 1 (enable timer 2 gate to speaker and enable speaker data)
    out dx, al                      ; Output to the port
    ; On each tick, the pc speaker will move between the 'in' and 'out' position, producing a sound wave

    ret
ENDP PlaySound
END