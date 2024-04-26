.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
scroll: .res 1
ppuctrl_settings: .res 1
pad1: .res 1
frame_counter: .res 1
animation_counter: .res 1

.exportzp player_x, player_y, pad1

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.import read_controller1

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
	LDA #$00

	; read controller
	JSR read_controller1

  ; update tiles *after* DMA transfer
	; and after reading controller state
	JSR update_player
  JSR draw_player

	LDA scroll
	CMP #$00 ; did we scroll to the end of a nametable?
	BNE set_scroll_positions
	; if yes,
	; Update base nametable
	LDA ppuctrl_settings
	EOR #%00000010 ; flip bit 1 to its opposite
	STA ppuctrl_settings
	STA PPUCTRL
	LDA #240
	STA scroll

set_scroll_positions:
	LDA #$00 ; X scroll first
	STA PPUSCROLL
	DEC scroll
	LDA scroll ; then Y scroll
	STA PPUSCROLL

  RTI
.endproc

.import reset_handler
.import draw_starfield
.import draw_objects

.export main
.proc main
	LDA #239	 ; Y is only 240 lines tall!
	STA scroll

  ; write a palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR
load_palettes:
  LDA palettes,X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palettes

	; write nametables
	LDX #$20
	JSR draw_starfield

	LDX #$28
	JSR draw_starfield

	JSR draw_objects

vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
	STA ppuctrl_settings
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc

.proc update_player
  PHP  ; Start by saving registers,
  PHA  ; as usual.
  TXA
  PHA
  TYA
  PHA

  LDA pad1        ; Load button presses
  AND #BTN_LEFT   ; Filter out all but Left
  BEQ check_right ; If result is zero, left not pressed
  DEC player_x  ; If the branch is not taken, move player left
check_right:
  LDA pad1
  AND #BTN_RIGHT
  BEQ check_up
  INC player_x
check_up:
  LDA pad1
  AND #BTN_UP
  BEQ check_down
  DEC player_y
check_down:
  LDA pad1
  AND #BTN_DOWN
  BEQ check_direction
  INC player_y

check_direction:
  LDA pad1
  AND #BTN_LEFT
  BEQ check_right_dir
  LDA #$03
  STA player_dir
  JMP done_checking

check_right_dir:
  LDA pad1
  AND #BTN_RIGHT
  BEQ check_up_dir
  LDA #$01
  STA player_dir
  JMP done_checking

check_up_dir:
  LDA pad1
  AND #BTN_UP
  BEQ check_down_dir
  LDA #$02
  STA player_dir
  JMP done_checking

check_down_dir:
  LDA pad1
  AND #BTN_DOWN
  BEQ done_checking
  LDA #$00
  STA player_dir

done_checking:
  INC animation_counter
  LDA animation_counter
  CMP #06
  BNE no_update

  LDA #0
  STA animation_counter
  INC frame_counter
  LDA frame_counter
  AND #%00000011
  STA frame_counter

no_update:
  PLA ; Done with updates, restore registers
  TAY ; and return to where we called this
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_player
  	; save registers
	PHP
	PHA
	TXA
	PHA
  TYA
  PHA
  
  
	LDA player_dir
	CMP #$01
	BEQ rightFrame
	CMP #$02
	BEQ upFrame
	CMP #$03
	BEQ leftFrame
	JMP downFrame

	; Player Walking left tile numbers
leftFrame:
    LDA frame_counter
    BEQ left_frame_1
    ; Draw left frame 2
    LDA #$05
    STA $0201
    LDA #$06
    STA $0205
    LDA #$15
    STA $0209
    LDA #$16
    STA $020d
    JMP attributes

left_frame_1:
    ; Draw left frame 1
    LDA #$01
    STA $0201
    LDA #$02
    STA $0205
    LDA #$11
    STA $0209
    LDA #$12
    STA $020d
    JMP attributes

rightFrame:
    LDA frame_counter
    BEQ right_frame_1
    ; Draw right frame 2
    LDA #$25
    STA $0201
    LDA #$26
    STA $0205
    LDA #$35
    STA $0209
    LDA #$36
    STA $020d
    JMP attributes

right_frame_1:
    ; Draw right frame 1
    LDA #$21
    STA $0201
    LDA #$22
    STA $0205
    LDA #$31
    STA $0209
    LDA #$32
    STA $020d
    JMP attributes

upFrame:
    LDA frame_counter
    BEQ up_frame_1
    ; Draw up frame 2
    LDA #$2b
    STA $0201
    LDA #$2c
    STA $0205
    LDA #$3b
    STA $0209
    LDA #$3c
    STA $020d
    JMP attributes

up_frame_1:
    ; Draw up frame 1
    LDA #$27
    STA $0201
    LDA #$28
    STA $0205
    LDA #$37
    STA $0209
    LDA #$38
    STA $020d
    JMP attributes

downFrame:
    LDA frame_counter
    BEQ down_frame_1
    ; Draw down frame 2
    LDA #$0b
    STA $0201
    LDA #$0c
    STA $0205
    LDA #$1b
    STA $0209
    LDA #$1c
    STA $020d
    JMP attributes

down_frame_1:
    ; Draw down frame 1
    LDA #$07
    STA $0201
    LDA #$08
    STA $0205
    LDA #$17
    STA $0209
    LDA #$18
    STA $020d
    JMP attributes
	
attributes:
	; Player attributes 
	LDA #$00
	STA $0202
	STA $0206
	STA $020a
	STA $020e

	STA $0204
	STA $0208
	STA $020c
	STA $0210

	; store tile locations
	; top left tile:
	LDA player_y
	STA $0200
	LDA player_x
	STA $0203

	; top right tile (x + 8):
	LDA player_y
	STA $0204
	LDA player_x
	CLC
	ADC #$08
	STA $0207

	; bottom left tile (y + 8):
	LDA player_y
	CLC				; Clearing carry flag preparing for addition. ->
	ADC #$08		; For now we will use this until we need to add something to a 16-bit number.
	STA $0208
	LDA player_x
	STA $020b

	; bottom right tile (x + 8, y + 8)
	LDA player_y
	CLC
	ADC #$08
	STA $020c
	LDA player_x
	CLC
	ADC #$08
	STA $020f

	; Restoring registers and return 
	PLA
  TAY
	PLA
 	TAX
 	PLA
 	PLP
 	RTS
.endproc


.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
palettes:
.byte $0f, $12, $23, $27
.byte $0f, $2b, $3c, $39
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $2d, $20, $16 
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

.segment "CHR"
; .incbin "input.chr"
.incbin "tanksANDtextures2.chr"