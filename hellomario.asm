.segment "HEADER"
.byte "NES"
.byte $1a
.byte $02 ; 2 * 16KB PRG ROM
.byte $01 ; 1 * 8KB CHR ROM
.byte %00000000 ; mappper and mirroring
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00, $00, $00, $00, $00 ; filler bytes
.segment "ZEROPAGE" ; MSB/  LSB 0 - FF
.segment "STARTUP"
Reset:
    SEI ; Disables all interrupts
    CLD ; disable decimal mode



    ; Disable sound IRQ
    LDX #$40    ; load value 40 into X
    STX $4017   ; store into memory address 4017


    ; Initialize the stack register
    LDX #$FF    ; FF, FE, FD...
    TXS         ; transfer X into the stack register

    INX         ; #$FF + 1 => #$00

    ; Zero out the PPU registers
    STX $2000
    STX $2001

    ; disable PCM
    STX $4010

:
    BIT $2002
    BPL :-

    TXA     ; transfer X (0) to A

CLEARMEM:
    STA $0000, X    ; $000 => $00FF
    STA $0100, X    ; $0100 => $01FF
    STA $0300, X    ; $0300 => $01FF
    STA $0400, X    ; $0400 => $01FF
    STA $0500, X    ; $0500 => $01FF
    STA $0600, X    ; $0600 => $01FF
    STA $0700, X    ; $0700 => $01FF
    STA $0800, X    ; $0800 => $01FF
    LDA #$FF
    STA $0200, X    ; $0200 = $02FF as FF
    LDA #$00
    INX
    BNE CLEARMEM ; when it rolls over sets a zero flag
; wait for vblank
:
    BIT $2002
    BPL :-

    LDA #$02
    STA $4014
    NOP

    ; $3F00
    LDA #$3F
    STA $2006
    LDA #$00
    STA $2006

    LDX #$00

LoadPalettes:
    LDA PaletteData, X
    STA $2007       ; $3F00, $3F01, $3F02 => $3F1F
    INX
    CPX #$20
    BNE LoadPalettes

    LDX #$00

LoadSprites:
    LDA SpriteData, X   ; load Sprite Data to A at Index X = 0 first
    STA $0200, X
    INX
    CPX #$20
    BNE LoadSprites


; Enable Interupts
    CLI

    LDA #%10010000  ; enable NMI change background to use second chr set of tiles ($1000)
    STA $2000
    ; Engabling sprites and background for left-most 8 pixels
    ; Enable sprites and backgrounds in general
    LDA #%00011110
    STA $2001



Loop:
    JMP Loop

NMI:
    LDA #$02 ; copy sprite data from $0200 => PPU memory for display
    STA $4014

    RTI ; RTS in other situations?

PaletteData:
    .byte $22,$29,$1A,$0F,$22,$36,$17,$0F,$22,$30,$21,$0F,$22,$27,$17,$0F   ;background palette
    .byte $22,$16,$27,$18,$22,$1A,$30,$27,$22,$16,$30,$27,$22,$0F,$36,$17   ;sprite palette data

SpriteData:
  .byte $08, $00, $00, $08  ; first sprite
  .byte $08, $01, $00, $10
  .byte $10, $02, $00, $08
  .byte $10, $03, $00, $10
  .byte $18, $04, $00, $08
  .byte $18, $05, $00, $10
  .byte $20, $06, $00, $08
  .byte $20, $07, $00, $10



.segment "VECTORS"
    .word NMI
    .word Reset
    ; 
.segment "CHARS"
    .incbin "hellomario.chr"
