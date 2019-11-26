  ; Basic header to allow RUN to work
  * = $0801
  .word (+), 2005
  .null $9e, format("%d", start)
+ .word 0

  * = $8000
start:
  sei

  ; Initialize sid playback
  lda #$00
  jsr $1000 ; sid init address

  ; Initialize VIC
  lda #%01111111
  ldx #$01
  sta $dc0d ; Cancel CIA interrupts
  sta $dd0d ; Cancel CIA 2 interrupts
  stx $d01a ; Turn on raster interrupts

  ; Interrupt at raster line 256 for sid playback
  lda #%00010000
  ldy #$00
  sta $d011 ; character mode
  sty $d012 ; set raster interrupt

  ; Load the snowflake interrupt routine
  lda #<sidisr
  ldy #>sidisr
  sta $314
  sty $315

  ; Clear screen
  lda #$00
  sta $d020 ; Set border and screen background to black
  sta $d021

  jsr clear_screen

  cli

  jmp *

snowisr:
  asl $d019 ; ack interrupt (re-enable it)
  dec scroll
  bpl +
  lda #%00010000
  sta $d011
  lda #$7
  sta scroll
  jsr swap_screen_buf
  jmp out
+ inc $d011
out:
  jsr set_sid_isr
  pla
  tay
  pla
  tax
  pla
  rti

copy_row .macro
  ldx #$28
- lda \1, x
  sta \2, x
  dex
  bne -
.endm

copy_to_back_buffer .macro
  #copy_row \1 + ($3e8 - $28), tmpbuf
  .for i=0, i<24, i+=1
  #copy_row \1 + (i * $28), \2 + ((i+1) * $28)
  .next
  #copy_row tmpbuf, \1
.endm

swap_screen_buf:
  lda #%00100000
  and $d018
  bne higher
  ; Enable 0x400 screen area
  lda #%00110000
  ora $d018
  sta $d018
  #copy_to_back_buffer $400, $c00
  rts
higher:
  ; Enable 0xC00 screen area
  lda #%11011111
  and $d018
  sta $d018
  #copy_to_back_buffer $c00, $400
  rts

sidisr:
  jsr $1003
  jsr set_snow_isr
  asl $d019 ; ack interrupt (re-enable it)
  pla
  tay
  pla
  tax
  pla
  rti

set_sid_isr:
  lda #<sidisr
  ldy #>sidisr
  sta $314
  sty $315
  lda #%01111111
  and $d011 ; unset raster interrupt high bit
  sta $d011
  rts

set_snow_isr:
  lda #<snowisr
  ldy #>snowisr
  sta $314
  sty $315
  lda #%10000000
  ora $d011 ; set raster interrupt high bit
  sta $d011
  rts

clear_screen:
  ldx #$00
- lda #$20
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  sta $c00,x
  sta $d00,x
  sta $e00,x
  sta $f00,x
  lda #$0F
  sta $d800,x
  sta $d900,x
  sta $da00,x
  sta $db00,x
  dex
  bne -

  ; generate snowflakes
  lda #$2E
  sta $450
  sta $438
  sta $44C
  sta $450
  sta $482
  sta $493
  sta $4A2
  sta $502
  sta $520
  sta $53F
  sta $595
  sta $5C2
  sta $602
  sta $633
  sta $6E3
  sta $680
  sta $699
  sta $702
  sta $742
  sta $772
  sta $791
  sta $7F2

  sta $438 + $800 + $28
  sta $44C + $800 + $28
  sta $450 + $800 + $28
  sta $482 + $800 + $28
  sta $493 + $800 + $28
  sta $4A2 + $800 + $28
  sta $502 + $800 + $28
  sta $520 + $800 + $28
  sta $53F + $800 + $28
  sta $595 + $800 + $28
  sta $5C2 + $800 + $28
  sta $602 + $800 + $28
  sta $633 + $800 + $28
  sta $6E3 + $800 + $28
  sta $680 + $800 + $28
  sta $699 + $800 + $28
  sta $702 + $800 + $28
  sta $742 + $800 + $28
  sta $772 + $800 + $28
  sta $791 + $800 + $28
  sta $7F2 + $800 + $28

  rts

scroll:
  .byte $7

tmpbuf:
  .fill $24, $0

* = $1000
  music .binary "Nantco_Bakker-Christmas_Medley.sid",126
