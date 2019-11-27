; vim: ft=64tass
.include "elf.s"

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
  lda #<snowisr
  ldy #>snowisr
  sta $314
  sty $315

  ; Clear screen
  lda #$00
  sta $d020 ; Set border and screen background to black
  sta $d021

  jsr clear_screen

  lda #$01
  sta $d015 ; Turn sprite 1 on
  sta $d01c ; Multicolor mode on

  lda #$02 ; sprite color
  sta $d027
  lda #$01 ; sprite multicolor 1
  sta $d025
  lda #$0a ; sprite multicolor 2
  sta $d026

  lda #$80 ; Sprite data at $2000
  sta $0800 - $8 ; Set sprite pointer
  sta $2800 - $8 ; Set sprite pointer

  cli

  jmp *

move_elf:
- lda $d010
  and #$01
  beq +
  lda $d000
  cmp #$56 ; TODO: Check the real max value
  bmi +
  lda #$00
  sta $d000
  lda #$FE
  and $d010
  sta $d010
+ lda $d000
  clc
  adc #$02
  sta $d000
  bcc +
  lda #$01
  ora $d010
  sta $d010

  ; Change elf's Y position
  ; using the sine table
+ lda $d000
  tax
  lda sine,x
  clc
  adc #$40
  adc elfscroll
  sta $d001
  ldx elfscroll
  inx
  stx elfscroll
  rts

elfisr:
  asl $d019 ; ack interrupt (re-enable it)

  jsr move_elf
  jsr set_snow_isr

  pla
  tay
  pla
  tax
  pla
  rti

snowisr:
  asl $d019 ; ack interrupt (re-enable it)

  lda scroll
  cmp #$6
  beq +
  jmp +++
+ lda #%10000000
  and $d018
  bne +
  #copy_to_back_buffer $400, $2400
  jmp ++
+ #copy_to_back_buffer $2400, $400
+ dec scroll
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
  #copy_row \1 + $28, \2
  #copy_row \1 + ($400 - $40), \2
  .for i=0, i<24, i+=1
  #copy_row \1 + (i * $28), \2 + ((i+1) * $28)
  .next
.endm

swap_screen_buf:
  lda #%10000000
  and $d018
  bne higher
  ; Enable 0x2400 screen area
  lda #%10000000
  ora $d018
  sta $d018
  rts
higher:
  ; Enable 0x400 screen area
  lda #%01111111
  and $d018
  sta $d018
  rts

sidisr:
  asl $d019 ; ack interrupt (re-enable it)
  jsr $1003
  jsr set_elf_isr

  pla
  tay
  pla
  tax
  pla
  rti

set_elf_isr:
  lda #<elfisr
  ldy #>elfisr
  sta $314
  sty $315
  lda #%10000000
  ora $d011 ; unset raster interrupt high bit
  sta $d011
  lda #$1C
  sta $d012
  rts

set_sid_isr:
  lda #<sidisr
  ldy #>sidisr
  sta $314
  sty $315
  lda #%01111111
  and $d011 ; unset raster interrupt high bit
  sta $d011
  lda #$FF
  sta $d012
  rts

set_snow_isr:
  lda #<snowisr
  ldy #>snowisr
  sta $314
  sty $315
  lda #%01111111
  and $d011 ; set raster interrupt high bit
  sta $d011
  lda #$00
  sta $d012
  rts

clear_screen:
  ldx #$00
- lda #$20
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  sta $2400,x
  sta $2500,x
  sta $2600,x
  sta $2700,x
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
  rts

scroll:
  .byte $7
elfscroll:
  .byte $0

tmpbuf:
  .fill $28, $0

.include "sine.s"

* = $1000
  music .binary "Nantco_Bakker-Christmas_Medley.sid",126
