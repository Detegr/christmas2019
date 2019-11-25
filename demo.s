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
  lda #%10111111
  ldy #$00
  sta $d011 ; bitmap mode, raster interrupt high bit
  sty $d012 ; set raster interrupt

  lda #%11101
  sta $d018

  lda #<sidisr
  ldy #>sidisr
  sta $314
  sty $315

  cli
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

  lda #$FE
  ldy #$FF
loop:
  .rept 100
  nop
  .next

  ; Limit loop speed
  pha
  txa
  beq +
  pla
  inx
  jmp loop

+ pla

prevsnow:
  sty $1ec0
  lda #$FE
snow:
  sta $2000
  ;sta $2001
  ;sta $2002
  ;sta $2003
  ;sta $2004
  ;sta $2005
  ;sta $2006
  ;sta $2007

  lda prevsnow+1
  clc
  adc #$40
  sta prevsnow+1
  bcc +
  inc prevsnow+2

+ lda snow+1
  clc
  adc #$40
  sta snow+1
  bcc +
  inc snow+2

+ inc prevsnow+2
  inc snow+2
  lda snow+2
  cmp #$40
  beq reset
  cmp #$41
  beq reset

  jmp +
reset:
  lda #$20
  sta snow+2
  lda #$00
  sta snow+1

  lda prevsnow+2
  sta resetprevsnow+2
  lda prevsnow+1
  sta resetprevsnow+1

  lda #$1e
  sta prevsnow+2
  lda #$c0
  sta prevsnow+1
resetprevsnow:
  sty $1ec0

+ inx
  jmp loop

sidisr:
  jsr $1003
  asl $d019 ; ack interrupt (re-enable it)
  pla
  tay
  pla
  tax
  pla
  rti

* = $1000
  music .binary "Nantco_Bakker-Christmas_Medley.sid",126
