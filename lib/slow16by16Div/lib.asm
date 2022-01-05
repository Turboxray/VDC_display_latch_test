
; Source: codebase64.org

; Performance: low end is ~860+ cycles and cap is ~960

slow16.divisor   = R0
slow16.dividend  = R1
slow16.remainder = R2
slow16.result    = slow16.dividend

slow16bitDiv:

      stz <slow16.remainder      ;preset remainder to 0
      stz <slow16.remainder+1
      ldx #16             ;repeat for each bit: ...

.divloop
      asl <slow16.dividend       ;dividend lb & hb*2, msb -> Carry
      rol <slow16.dividend+1
      rol <slow16.remainder      ;remainder lb & hb * 2 + msb from carry
      rol <slow16.remainder+1
      lda <slow16.remainder
      sec
      sbc <slow16.divisor        ;substract divisor to see if it fits in
      tay                 ;lb result -> Y, for we may need it later
      lda <slow16.remainder+1
      sbc <slow16.divisor+1
    bcc .skip             ;if carry=0 then divisor didn't fit in yet

      sta <slow16.remainder+1    ;else save substraction result as new remainder,
      sty <slow16.remainder
      inc <slow16.result         ;and INCrement result cause divisor fit in 1 times

.skip
      dex
     bne .divloop
   rts