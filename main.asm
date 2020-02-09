	.inesprg 1 ; 16kb PRG
	.ineschr 1 ; 8kb CHR
	.inesmap 0 ; no bank switching
	.inesmir 0 ; mirror background



	.bank 0
	.org $C000
RESET:
	SEI			; disable IRQs
	CLD			; disable decimal mode (doesnt do anything)
	LDX #$40
	STX $4017	; disable APU fram IRQ
	LDX #$FF
	TXS			; set up stack
	INX			; X is 0 now
	STX $2000	; disable NMI
	STX $2001	; disable rendering
	STX $4010	; disable DMC IRQ
	
vblankwait1:	; wait for the PPU to be ready
	BIT $2002
	BPL vblankwait1
	
clrmem:
	LDA #$00
	STA $0000, x
	STA $0100, x
	STA $0200, x
	STA $0300, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x
	INX
	BNE clrmem

vblankwait2:	; second vblank wait
	BIT $2002
	BPL vblankwait2

LoadPalette:
	LDA $2002	; read PPU status to reset the high/low latch to high
	LDA #$3F
	STA $2006	; write the high byte of $3F10 address
	LDA #$10
	STA $2006	; write the low byte of $3F10

	LDX #$00	; start out at 0

LoopLoadPalette:
	LDA Palette, x	; load data from address (Palette + the value in x)
					; 1st time through loop it will load
	STA $2007		; write to PPU
	INX				; X = X + 1
	CPX	#$20		; compare x with hex $20, decimal 32
	BNE LoopLoadPalette ; branch to LoopLoadPalette 

SpriteDisplay:
	LDA #$80
	STA $0200	; set to x
	STA $0203	; set to y
	LDA #$00
	STA $0201
	STA $0202
	
	LDA #%10000000
	STA $2000
	
	LDA #%00010000
	STA $2001

Forever:
	JMP Forever
	
NMI:
	LDA #$00
	STA $2003 ; set the low byte (00) of the RAM address
	LDA #$02
	STA $4014	; set the high byte (02) of the RAM address, start
	RTI
	
;;;;;;;;;;;;;;;;;;;;;;;;;

	.bank 1
	.org $E000 ; where we're storing our raw bytes - initial palette data we're using to initialise
Palette:
; Sprite Data
  .db $0F,$16,$27,$18,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C
; Background Data
  .db $0F,$31,$32,$33,$0F,$35,$36,$37,$38,$39,$3A,$3B,$0F,$3D,$3E,$0F

	.org $FFFA
	.dw NMI
	.dw RESET
	.dw 0

; creating our CHR ROM	
	.bank 2
	.org $0000
	.incbin "mario.chr"