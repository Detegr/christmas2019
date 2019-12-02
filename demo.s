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

  lda #$03
  sta $d015 ; Turn sprites 1 and 2 on
  lda #$01
  sta $d01c ; Multicolor mode for sprite 1

  lda #$02 ; sprite color
  sta $d027 ; sprite 1

  lda #$01 ; sprite color
  sta $d028 ; sprite 2

  lda #$01 ; sprite 1 multicolor 1
  sta $d025
  lda #$0a ; sprite 1 multicolor 2
  sta $d026

  lda #$80 ; Sprite 1 data at $2000
  sta $0800 - $8 ; Set sprite 1 pointer
  sta $2800 - $8 ; Set sprite 1 pointer

  lda #$85 ; Sprite 2 data at $2140
  sta $0800 - $7 ; Set sprite 2 pointer
  sta $2800 - $7 ; Set sprite 2 pointer

  lda #$40
  sta $d002
  sta $d003

  lda #$00
  sta $d010
  lda #$50
  sta $d000

  cli
  jmp *

move_sprite_right .macro
  ; \1 is the sprite x coordinate location
  ; \2 is the bit pattern to extract the 9th bit
  ;    from $d010
  ; \3 is the reverse bit pattern of \2
- lda $d010
  and \2
  beq +
  lda \1
  cmp #$56 ; TODO: Check the real max value
  bmi +
  lda #$00
  sta \1
  lda \3
  and $d010
  sta $d010
+ lda \1
  clc
  adc #$02
  sta \1
  bcc +
  lda \2
  ora $d010
  sta $d010
+ nop
.endm

move_sprite_left .macro
  ; \1 is the sprite x coordinate location
  ; \2 is the bit pattern to extract the 9th bit
  ;    from $d010
  ; \3 is the reverse bit pattern of \2

  ; check 9th bit
- lda $d010
  and \2
  beq ++

  ; 9th bit set
  lda \1
  clc
  sbc #$01
  sta \1
  bcs +++

  ; 9th bit set and x overflown
  ; unset 9th bit and set x=$FF
+ lda #$FF
  sta \1
  lda \3
  and $d010
  sta $d010
  jmp ++

  ; decrement x
  ; set x=$155 if x == 0
+ lda \1
  clc
  sbc #$01
  sta \1
  bcs +
  lda $d010
  ora \2
  sta $d010
  lda #$55
  sta \1
+ nop
.endm

move_elf:
  #move_sprite_right $d000, #$01, #$FE
  #move_sprite_left $d002, #$02, #$FD

  ; Change elf's Y position
  ; using the sine table
+ lda $d000
  tax
  lda sine,x
  adc #$40
  adc elfscroll
  sta $d001
  ldx elfscroll
  inx
  stx elfscroll

  ; Change logo's Y position
  ; using the sine table
  lda $d002
  tax
  lda sine,x
  sbc #$70
  adc logoscroll
  sta $d003
  ldx logoscroll
  dex
  stx logoscroll
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
  beq first
  cmp #$5
  beq second
  cmp #$4
  beq third
  cmp #$3
  beq fourth
  jmp snowfall

first:
  #copy_row $428, $2400
  #copy_row $400 + ($400 - $40), $2400
  #copy_to_back_buffer $400, $2400, 0
  jmp snowfall

second:
  #copy_to_back_buffer $400, $2400, 1
  jmp snowfall

third:
  #copy_to_back_buffer $400, $2400, 2
  jmp snowfall

fourth:
  #copy_to_back_buffer $400, $2400, 3

snowfall:
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
  lda #%10000000
  and $d018
  bne +
  #internal_copy_to_back_buffer \1, \2, \3
  jmp ++
+ #internal_copy_to_back_buffer \2, \1, \3
+ nop
.endm

internal_copy_to_back_buffer .macro
  .for i=(\3 * 6), i<((\3 + 1) * 6), i+=1
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
logoscroll:
  .byte $ff

tmpbuf:
  .fill $28, $0

.include "sine.s"

* = $1000
  music .binary "Nantco_Bakker-Christmas_Medley.sid",126
