  * = $2000

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

  lda #%10011111
  ldy #$00

  sta $d011
  sty $d012 ; set raster interrupt

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
  lda #$20 ; Space character
clr:
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  dex
  bne clr

  jmp *

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
