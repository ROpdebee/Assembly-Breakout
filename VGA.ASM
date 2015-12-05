;=============================================================================
; 32-bit Assembler VGA library.
;
; For use under DMPI 0.9 protected mode.
;
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Copyright (c) 2015, Tim Bruylants <tim.bruylants@gmail.com>
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions
; are met:
;
; 1. Redistributions of source code must retain the above copyright notice,
;    this list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
;
; 3. Neither the name of the copyright holder nor the names of its
;    contributors may be used to endorse or promote products derived from this
;    software without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
; POSSIBILITY OF SUCH DAMAGE.
;
;=============================================================================

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "vga.inc"

; VGA DAC ports
PORT_VGA_DAC_READ   equ 03c7h   ; write
PORT_VGA_DAC_WRITE  equ 03c8h   ; write
PORT_VGA_DAC_DATA   equ 03c9h   ; read/write

;=============================================================================
; Uninitialized DATA
;=============================================================================
UDATASEG

;=============================================================================
; DATA
;=============================================================================
DATASEG

;=============================================================================
; CODE
;=============================================================================
CODESEG

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Wait for vertical blank.
;
; ARGUMENTS:
;   none
; RETURNS:
;   nothing
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROC vga_waitVBE
    USES    eax, edx

    mov     dx, 03dah           ; VGA status port
@@waitVBlank_wait1:             ; if already in VB, then wait until VB finishes
    in      al, dx              ; read status
    and     al, 8               ; test bit 3
    jnz     @@waitVBlank_wait1  ; busy wait if in VB
@@waitVBlank_wait2:             ; wait until begin of a new VB
    in      al, dx              ; read status
    and     al, 8               ; test bit 3
    jz      @@waitVBlank_wait2  ; busy wait if NOT in VB

    ret
ENDP vga_waitVBE

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Clear the VGA palette (set everything to black).
;
; ARGUMENTS:
;   none
; RETURNS:
;   nothing
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROC vga_clearPalette
    USES    eax, ecx, edx

    pushfd
    cli

    mov     edx, PORT_VGA_DAC_WRITE ; VGA DAC 'set' port
    xor     eax, eax                ; set the first color to start with
    out     dx, al                  ; write to the VGA card
    inc     edx                     ; EDX = 03c9h, the VGA DAC 'data' port
    mov     ecx, 3 * 256            ; number of colors
@@l:
    out     dx, al                  ; write ECX bytes to VGA card
    dec     ecx
    jnz     @@l

    popfd

    ret
ENDP vga_clearPalette

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Set the VGA palette.
;
; Assumes DS points to the data segment of the palette.
;
; ARGUMENTS:
;   DWORD   Offset to the palette
;   BYTE    First color index to start with
;   DWORD   Number of colors to change (max = 256)
; RETURNS:
;   nothing
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROC vga_setPalette
    ARG     @@palette:dword, \
            @@startIndex:byte, \
            @@numberOfColors:dword
    USES    eax, ecx, edx, esi

    pushfd
    cli

    mov     edx, PORT_VGA_DAC_WRITE ; VGA DAC 'set' port
    mov     al, [@@startIndex]      ; set the first color to start with
    out     dx, al                  ; write to the VGA card

    inc     edx                     ; EDX = 03c9h, the VGA DAC 'data' port
    mov     esi, [@@palette]        ; make ESI point to the palette data
    mov     ecx, [@@numberOfColors] ; number of colors
    lea     ecx, [ecx + 2 * ecx]    ; ECX = ECX * 3
    rep     outsb                   ; write ECX bytes to VGA card

    popfd

    ret
ENDP vga_setPalette

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Set the VGA palette.
;
; Assumes DS points to the data selector of the palette (where colors will be
; written).
;
; ARGUMENTS:
;   DWORD   Offset to the palette to write colors to
;   BYTE    First color index to start with
;   DWORD   Number of colors to read (max = 256)
; RETURNS:
;   nothing
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROC vga_getPalette
    ARG     @@palette:dword, \
            @@startIndex:byte, \
            @@numberOfColors:dword
    USES    eax, ecx, edx, edi

    pushfd
    cli

    mov     edx, PORT_VGA_DAC_READ  ; VGA DAC 'get' port
    mov     al, [@@startIndex]      ; set the first color to start with
    out     dx, al                  ; write to the VGA card

    add     edx, 2                  ; EDX = 03c9h, the VGA DAC 'data' port
    mov     edi, [@@palette]        ; make ESI point to the palette data
    mov     ecx, [@@numberOfColors] ; number of colors
    lea     ecx, [ecx + 2 * ecx]    ; ECX = ECX * 3
    rep     insb                   ; read ECX bytes from VGA card

    popfd

    ret
ENDP vga_getPalette

END

