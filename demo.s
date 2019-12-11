; vim: ft=64tass
debug = 0

.include "elf.s"

  ; Basic header to allow RUN to work
  * = $0801
  .word (+), 2005
  .null $9e, format("%d", start)
+ .word 0

  * = $8000
start:
  sei

  lda #$35 ; ram visible in $A000-$BFFF and $E000-$FFFF
  sta $01

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
  sta $fffe
  sty $ffff

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

  lda #$50
  sta $d002
  sta $d003

  lda #$D0
  sta $d000
  sta $d001

  ; screen at 0x400
  ; charset at 0x2800
  lda #$1a
  sta $d018

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
  ;ldx elfscroll
  ;inx
  ;stx elfscroll

  ; Change logo's Y position
  ; using the sine table
  lda $d002
  tax
  lda sine,x
  sbc #$40
  adc logoscroll
  sta $d003
  ;ldx logoscroll
  ;dex
  ;stx logoscroll
  rts

elfisr:
.if debug
  lda #$01
  sta $d020
  sta $d021
.endif
  asl $d019 ; ack interrupt (re-enable it)

  jsr move_elf
  jsr set_snow_isr

.if debug
  lda #$00
  sta $d020
  sta $d021
.endif
  rti

snowisr:
.if debug
  lda #$02
  sta $d020
  sta $d021
.endif
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
  lda #$7
  sta scroll
  jsr swap_screen_buf
  jsr reset_snowflake
  jmp ++
+ jsr step_snowflake
+ jsr set_rasterbar_isr
.if debug
  lda #$00
  sta $d020
  sta $d021
.endif
  rti

reset_snowflake:
  ; Snowflake character
  lda #%00010000
  sta $2970
  lda #%01010100
  sta $2971
  lda #%00111000
  sta $2972
  lda #%11101110
  sta $2973
  lda #%00111000
  sta $2974
  lda #%01010100
  sta $2975
  lda #%00010000
  sta $2976
  lda #$00
  sta $2977

  ; Initialize the character that
  ; the falling snowflake overflows into
  ; to all zeros
  lda #$00
  sta $2980
  sta $2981
  sta $2982
  sta $2983
  sta $2984
  sta $2985
  sta $2986
  sta $2987
  rts

step_snowflake:
  ; Copy snowflake character data one step down
  ; within the 8x8 character memory (0x2E).
  ; Also copy the overflowing bytes to the next character (0x30)
  lda #$00

  ldx $2970
  sta $2970

  lda $2971
  stx $2971

  ldx $2972
  sta $2972

  lda $2973
  stx $2973

  ldx $2974
  sta $2974

  lda $2975
  stx $2975

  ldx $2976
  sta $2976

  lda $2977
  stx $2977

  ldx $2980
  sta $2980

  lda $2981
  stx $2981

  ldx $2982
  sta $2982

  lda $2983
  stx $2983

  ldx $2984
  sta $2984

  lda $2985
  stx $2985

  ldx $2986
  sta $2986

  lda $2987
  stx $2987
  rts

rasterbarisr:
  asl $d019
  lda #$04
  sta $d020
  sta $d021
  jsr set_rasterbar_off_isr
  rti

rasterbaroffisr:
  asl $d019
  lda #$00
  sta $d020
  sta $d021
  jsr set_sid_isr
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
  .if \3 == 0
  #copy_row \1 + $28, \2
  #copy_row \1 + ($400 - $40), \2
  .endif
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

.if debug
  lda #$07
  sta $d020
  sta $d021
.endif

  jsr $1003
  jsr set_elf_isr

.if debug
  lda #$00
  sta $d020
  sta $d021
.endif

  rti

set_rasterbar_isr:
  lda #<rasterbarisr
  ldy #>rasterbarisr
  sta $fffe
  sty $ffff
  lda #$80
  sta $d012
  rts

set_rasterbar_off_isr:
  lda #<rasterbaroffisr
  ldy #>rasterbaroffisr
  sta $fffe
  sty $ffff
  lda #$b0
  sta $d012
  rts

set_elf_isr:
  lda #<elfisr
  ldy #>elfisr
  sta $fffe
  sty $ffff
  lda #%10000000
  ora $d011 ; unset raster interrupt high bit
  sta $d011
  lda #$1C
  sta $d012
  rts

set_sid_isr:
  lda #<sidisr
  ldy #>sidisr
  sta $fffe
  sty $ffff
  lda #%01111111
  and $d011 ; unset raster interrupt high bit
  sta $d011
  lda #$FF
  sta $d012
  rts

set_snow_isr:
  lda #<snowisr
  ldy #>snowisr
  sta $fffe
  sty $ffff
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

  ; Copy character rom to ram
  ldy $01
  lda #$31 ; make character rom visible
  sta $01

  lda $d000,x
  sta $2800,x
  lda $d100,x
  sta $2900,x
  lda $d200,x
  sta $2a00,x
  lda $d300,x
  sta $2b00,x
  lda $d400,x
  sta $2c00,x
  lda $d500,x
  sta $2d00,x
  lda $d600,x
  sta $2e00,x
  lda $d700,x
  sta $2f00,x
  dex

  sty $01 ; Restore ram visibility
  bne -

  jsr generate_snowflakes
  jsr reset_snowflake
  rts

generate_snowflakes:
  ; Copy $2E character to pseudo-random positions
  ; Copy $30 character one row below $2E characters
  lda #$2E
  ldy #$30
  sta $450
  sty $450+$28
  sta $438
  sty $438+$28
  sta $44C
  sty $44C+$28
  sta $450
  sty $450+$28
  sta $482
  sty $482+$28
  sta $493
  sty $493+$28
  sta $4A2
  sty $4A2+$28
  sta $502
  sty $502+$28
  sta $520
  sty $520+$28
  sta $53F
  sty $53F+$28
  sta $595
  sty $595+$28
  sta $5C2
  sty $5C2+$28
  sta $602
  sty $602+$28
  sta $633
  sty $633+$28
  sta $6E3
  sty $6E3+$28
  sta $680
  sty $680+$28
  sta $699
  sty $699+$28
  sta $702
  sty $702+$28
  sta $742
  sty $742+$28
  sta $772
  sty $772+$28
  sta $791
  sty $791+$28
  sta $7F2
  sty $7F2+$28
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
