snowflake .macro
  asl $d019 ; ack interrupt (re-enable it)
  ldy #$FF

\1_prevsnow:
  sty \2
+ ldx \2 - $100
  lda #$FE
\1_snow:
  sta \2

  txa
  beq +

  lda \1_snow+1
  sta \1_prevsnow+1
  lda \1_snow+2
  sta \1_prevsnow+2

  inc \1_snow+1
  dex
  stx \2 - $100
  jmp \1_out

+ ldx #$7
  stx \2 - $100

  lda \1_snow+1
  sta \1_prevsnow+1
  clc
  adc #$39
  sta \1_snow+1
  bcc +
  inc \1_snow+2

+ inc \1_snow+2
  lda \1_snow+2
  cmp #$40
  beq \1_reset
  cmp #$41
  beq \1_reset
  jmp \1_out
\1_reset:
  lda #>\2
  sta \1_snow+2
  lda #<\2
  sta \1_snow+1
\1_out:
.endm

  * = $8000

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
  lda #%00111111
  ldy #$00
  sta $d011 ; bitmap mode, raster interrupt high bit
  sty $d012 ; set raster interrupt

  lda #%11101
  sta $d018

  lda #<snowisr
  ldy #>snowisr
  sta $314
  sty $315

  ; End of sid playback initialization

  ; Clear screen
  lda #$00
  sta $d020 ; Set border and screen background to black
  sta $d021

  tax
clr:
  lda #$01
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  lda #$FF
  sta $2000,x
  sta $2100,x
  sta $2200,x
  sta $2300,x
  sta $2400,x
  sta $2500,x
  sta $2600,x
  sta $2700,x
  sta $2800,x
  sta $2900,x
  sta $2a00,x
  sta $2b00,x
  sta $2c00,x
  sta $2d00,x
  sta $2e00,x
  sta $2f00,x
  sta $3000,x
  sta $3100,x
  sta $3100,x
  sta $3200,x
  sta $3300,x
  sta $3400,x
  sta $3500,x
  sta $3600,x
  sta $3700,x
  sta $3800,x
  sta $3900,x
  sta $3a00,x
  sta $3b00,x
  sta $3c00,x
  sta $3d00,x
  sta $3e00,x
  sta $3f00,x
  dex
  bne clr

  lda #$7
  sta $2000 - $100
  sta $2008 - $100
  sta $2020 - $100
  cli

  jmp *

snowisr:
  #snowflake s, $2000
  #snowflake s2, $2008
  #snowflake s3, $2020
out:
  jsr set_sid_isr
  pla
  tay
  pla
  tax
  pla
  rti

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
  lda #%10111111
  ldy #$00
  sta $d011 ; bitmap mode, raster interrupt high bit
  sty $d012 ; set raster interrupt
  rts

set_snow_isr:
  lda #<snowisr
  ldy #>snowisr
  sta $314
  sty $315
  lda #%00111111
  ldy #$00
  sta $d011 ; bitmap mode, raster interrupt high bit
  sty $d012 ; set raster interrupt
  rts

* = $1000
  music .binary "Nantco_Bakker-Christmas_Medley.sid",126
