


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;//
VDCuserISR.IRQ:


;............................................
.check
    pha
    phx
    phy

            lda IRQ.ackVDC
            sta <vdc_status
            bit #$04
        bne .hsync
            bit #$20
        bne .vsync
;............................................
.hsync
            ldx <rcr_offset
            st0 #CR
            lda <disp,x
            sta $0002

            st0 #RCR
            lda <RCRline,x
            sta $0002
            lda <RCRline+1,x
            sta $0003

            stz $402
            lda #$01
            sta $403
            lda #$07
            sta $404
            txa
            inc a
            inc a
            cmp #$03
        bcc .skip
            cla
.skip
            sta <rcr_offset
            lsr a
            sta $405


.vsync_check
            lda <vdc_status
            bit #$20
        bne .vsync

;............................................
.out
            lda <vdc_reg
            sta $0000
    ply
    plx
    pla

    rti

;............................................
.vsync

            VDC.reg CR , #(BG_ON|SPR_ON|VINT_ON|HINT_ON)
            stz $402
            lda #$01
            sta $403
            lda #$3f
            sta $404
            stz $405

            stz __vblank

        jmp .out


