init_snowflake .macro
  sta counters + \1
.endm

scrnmem = $2000

bitmap_ram_pos .function i
.endf scrnmem + ($8 * i)

snowflake_counter_pos .function i
.endf counters + i

snowflake .macro
  ; Load empty pattern to Y register
  ; This is used to clear the previously used pixel
  ldy #$FF

\1_prevsnow:
  ; Clear up previous snowflake position
  sty bitmap_ram_pos(\2)
  ; Load X counter from memory location
+ ldx snowflake_counter_pos(\2)
  ; Load snowflake pattern (one pixel set)
  lda #$FE
\1_snow:
  ; Write to current snowflake position
  sta bitmap_ram_pos(\2)

  ; Move snowflake counter to accumulator
  txa
  ; Loop 8 times to correctly animate the
  ; 8x8 cell. If the counter is zero, jump
  ; to the next 8x8 cell.
  beq +

  ; Copy the current snowflake location to
  ; prevsnow address
  lda \1_snow+1
  sta \1_prevsnow+1
  lda \1_snow+2
  sta \1_prevsnow+2

  ; Advance the snowflake one pixel down
  inc \1_snow+1
  dex
  ; Decrement snowflake counter
  stx snowflake_counter_pos(\2)
  jmp \1_out

  ; Reload snowflake counter
+ ldx #$7
  stx snowflake_counter_pos(\2)

  ; Move the snowflake to next 8x8 cell
  ; Start by incrementing low nibble by 0x39
  lda \1_snow+1
  sta \1_prevsnow+1
  clc
  adc #$39
  sta \1_snow+1
  bcc +
  ; Increment the high nibble if snow+1 overflows
  inc \1_snow+2

  ; Increment high nibble, reset if it reaches 0x40
  ; as 0x3FFF is the end of bitmap ram
+ inc \1_snow+2
  lda \1_snow+2
  cmp #$40
  beq \1_reset
  cmp #$41
  beq \1_reset
  jmp \1_out
\1_reset:
  ; Reset snowflake position to the initial position
  lda #>(bitmap_ram_pos(\2))
  sta \1_snow+2
  lda #<(bitmap_ram_pos(\2))
  sta \1_snow+1
\1_out:
.endm
