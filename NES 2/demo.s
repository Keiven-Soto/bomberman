;Noel Vargas Padilla 802-19-7297
;Keiven Soto 902-19-3707

.segment "HEADER"
  ; .byte "NES", $1A      ; iNES header identifier
  .byte $4E, $45, $53, $1A
  .byte 2               ; 2x 16KB PRG code
  .byte 1               ; 1x  8KB CHR data
  .byte $01, $00        ; mapper 0, vertical mirroring

.segment "VECTORS"
  ;; When an NMI happens (once per frame if enabled) the label nmi:
  .addr nmi
  ;; When the processor first turns on or is reset, it will jump to the label reset:
  .addr reset
  ;; External interrupt IRQ (unused)
  .addr 0

; "nes" linker config requires a STARTUP section, even if it's empty
.segment "STARTUP"

; Main code segment for the program
.segment "CODE"

.include "constants.inc"

reset:
  sei		; disable IRQs
  cld		; disable decimal mode
  ldx #$40
  stx $4017	; disable APU frame IRQ
  ldx #$ff 	; Set up stack
  txs		;  .
  inx		; now X = 0
  stx PPUCTRL	; disable NMI
  stx PPUMASK 	; disable rendering
  stx $4010 	; disable DMC IRQs

;; first wait for vblank to make sure PPU is ready
vblankwait1:
  bit PPUSTATUS
  bpl vblankwait1

clear_memory:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne clear_memory
  
;; second wait for vblank, PPU is ready after this
vblankwait2:
  bit PPUSTATUS
  bpl vblankwait2

.export main
main:
  load_sprites:
    lda PPUSTATUS
    lda #$00
    sta OAMADDR

    ldx #0
    loop_load_sprites:
      lda sprites, X
      sta OAMDATA
      inx
      cpx #64
      bne loop_load_sprites

  load_palettes:
    lda PPUSTATUS
    lda #$3f
    sta PPUADDR
    lda #$00
    sta PPUADDR

    ldx #$00
    @loop:
      lda palettes, x
      sta PPUDATA
      inx
      cpx #$20
      bne @loop

enable_rendering:
  lda #%10000000	; Enable NMI
  sta PPUCTRL
  lda #%00010110; Enable background and sprite rendering in PPUMASK.
  sta PPUMASK

forever:
  jmp forever

nmi:
  lda #$00
  sta PPUSCROLL
  lda #$00
  sta PPUSCROLL

  rti


palettes:
; background palette
.byte $0F, $16, $13, $37
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00

; sprite palette
.byte $0F, $16, $13, $37
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00


sprites:

; tank face up
.byte $00, $02, $00, $10
.byte $00, $03, $00, $18
.byte $08, $12, $00, $10
.byte $08, $13, $00, $18

; tank moving up
.byte $00, $04, $00, $20
.byte $00, $05, $00, $28
.byte $08, $14, $00, $20
.byte $08, $15, $00, $28

; tank looking down
.byte $00, $06, $00, $30
.byte $00, $07, $00, $38
.byte $08, $16, $00, $30
.byte $08, $17, $00, $38

; tank moving down
.byte $00, $08, $00, $40
.byte $00, $09, $00, $48
.byte $08, $18, $00, $40
.byte $08, $19, $00, $48


; Character memory
.segment "CHARS"
.incbin "tanks.chr"