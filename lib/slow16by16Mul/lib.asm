

;16-bit multiply with 32-bit product
;source from 6502.org

slow16.multiplier   = R0
slow16.multiplicand = R1
slow16.product      = R2

mult16.16:
      lda   #$00
      sta   <slow16.product+2      ; clear upper bits of product
      sta   <slow16.product+3
      ldx   #$10           ; set binary count to 16
.shift_r
      lsr   <slow16.multiplier+1   ; divide multiplier by 2
      ror   <slow16.multiplier
    bcc .rotate_r
      lda   <slow16.product+2      ; get upper half of product and add multiplicand
      clc
      adc   <slow16.multiplicand
      sta   <slow16.product+2
      lda   <slow16.product+3
      adc   <slow16.multiplicand+1
.rotate_r
      ror   a               ; rotate partial product
      sta   <slow16.product+3
      ror   <slow16.product+2
      ror   <slow16.product+1
      ror   <slow16.product
      dex
    bne   .shift_r
rts

mult8.16:
      lda   #$00
      sta   <slow16.product+2      ; clear upper bits of product
      sta   <slow16.product+3
      ldx   #$8            ; set binary count to 16
.shift_r
      lsr   <slow16.multiplier+1   ; divide multiplier by 2
      ror   <slow16.multiplier
    bcc .rotate_r
      lda   <slow16.product+2      ; get upper half of product and add multiplicand
      clc
      adc   <slow16.multiplicand
      sta   <slow16.product+2
      lda   <slow16.product+3
      adc   <slow16.multiplicand+1
.rotate_r
      ror   a               ; rotate partial product
      sta   <slow16.product+3
      ror   <slow16.product+2
      ror   <slow16.product+1
      ror   <slow16.product
      dex
    bne   .shift_r
rts


