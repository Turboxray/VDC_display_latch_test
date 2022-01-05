
;
;    {Assemble with PCEAS: ver 3.23 or higher}
;
;   Turboxray '21
;



;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;..............................................................................................................

    list
    mlist

;..................................................
;                                                 .
;  Logical Memory Map:                            .
;                                                 .
;            $0000 = Hardware bank                .
;            $2000 = Sys Ram                      .
;            $4000 = Subcode                      .
;            $6000 = Data 0 / Cont. of Subcode    .
;            $8000 = Data 1                       .
;            $A000 = Data 2                       .
;            $C000 = Main                         .
;            $E000 = Fixed Libray                 .
;                                                 .
;..................................................


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;//  Vars

    .include "../base_func/vars.inc"
    .include "../base_func/video/vdc/vars.inc"
    .include "../base_func/video/vdc/sprites/vars.inc"
    .include "../base_func/IO/gamepad/vars.inc"
    .include "../base_func/IO/irq_controller/vars.inc"
    .include "../base_func/IO/mapper/mapper.inc"

    .include "../lib/controls/vars.inc"
    .include "../lib/input_controls/vars.inc"
    .include "../lib/HsyncISR/vars.inc"
    .include "../lib/random/16bit/vars.inc"

;....................................
    .code

    .bank $00, "Fixed Lib/Start up"
    .org $e000
;....................................

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Support files: equates and macros
    .include "../base_func/base.inc"
    .include "../base_func/video/video.inc"
    .include "../base_func/video/vdc/vdc.inc"
    .include "../base_func/video/vdc/sprites/sprites.inc"
    .include "../base_func/video/vce/vce.inc"
    .include "../base_func/timer/timer.inc"
    .include "../base_func/IO/irq_controller/irq.inc"
    .include "../base_func/IO/mapper/mapper.inc"
    .include "../base_func/audio/wsg/wsg.inc"
    .include "../base_func/IO/gamepad/gamepad.inc"

    .include "../lib/controls/controls.inc"
    .include "../lib/input_controls/input_controls.inc"
    .include "../lib/HsyncISR/hsync.inc"
    .include "../lib/random/16bit/random_16bit.inc"



;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Startup and fix lib @$E000

startup:

        InitialStartup
        call init_audio
        call init_video

        ;................................
        ;Set video parameters
        VCE.reg MID_RES|H_FILTER_ON
        VDC.reg HSR  , #$0504
        VDC.reg HDR  , #$0628
        VDC.reg VSR  , #$0F02
        VDC.reg VDR  , #$00cf
        VDC.reg VDE  , #$0023
        VDC.reg DCR  , #AUTO_SATB_ON
        VDC.reg CR   , #$0000
        VDC.reg SATB , #$7F00
        VDC.reg MWR  , #SCR64_64

        IRQ.control IRQ2_ON|VIRQ_ON|TIRQ_OFF

        TIMER.port  _7.00khz
        TIMER.cmd   TMR_OFF

        MAP_BANK #MAIN, MPR6
        jmp MAIN

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Data / fixed bank
    .include "../base_func/video/print/lib.asm"
    .include "../base_func/video/vdc/lib.asm"
    .include "../base_func/video/vdc/sprites/lib.asm"
    .include "../base_func/IO/gamepad/lib.asm"
    .include "../base_func/init/InitHW.asm"


; Lib stuffs
    .include "../lib/controls/lib.asm"
    .include "../lib/input_controls/lib.asm"
    .include "../lib/HsyncISR/lib.asm"
    .include "../lib/slow16by16Mul/lib.asm"
    .include "../lib/slow16by16Div/lib.asm"
    .include "../lib/random/16bit/lib.asm"


;end DATA
;//...................................................................

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Interrupt routines

;//........
TIRQ.custom
    jmp [timer_vect]

TIRQ:   ;// Not used
        BBS2 <vector_mask, TIRQ.custom
        stz $1403
        rti

;//........
; BRK.custom
    jmp [brk_vect]
BRK:
        ; BBS1 <vector_mask, BRK.custom
        rti

;//........
VDC.custom
    jmp [vdc_vect]

VDC:
        BBS0 <vector_mask, VDC.custom
          pha
        lda IRQ.ackVDC
        sta <vdc_status
        bit #$20
        bne VDC.vsync
VDC.hsync
        BBS4 <vector_mask, VDC.custom.hsync
        BBS5 <vdc_status, VDC.vsync
          pla
        rti

VDC.custom.hsync
    jmp [vdc_hsync]

VDC.custom.vsync
    jmp [vdc_vsync]

VDC.vsync
        phx
        phy
        BBS3 <vector_mask, VDC.custom.vsync

VDC.vsync.rtn
        ply
        plx
        pla
      stz __vblank
  rti

;//........
NMI:
        rti

;end INT

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// INT VECTORS

  .org $fff6

    .dw BRK
    .dw VDC
    .dw TIRQ
    .dw NMI
    .dw startup

;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;Bank 0 end





;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Main code bank @ $C000

;....................................
    .bank $01, "MAIN"
    .org $c000
;....................................


MAIN:

        ;................................
        ;Turn display on
        VDC.reg CR , #(BG_ON|SPR_ON|VINT_ON|HINT_ON)
        MOVE.w #(BG_ON|SPR_ON|VINT_ON|HINT_ON), disp
        MOVE.w #(BG_ON|SPR_ON|VINT_ON|HINT_ON), disp2


        ;................................
        ;Load font
        loadCellToVram Font, $1000
        loadCellToCram.BG Font, 0

        ;...............................
        ; Set VDC ISRs
        ISR.setVector VDC_VEC , VDCuserISR.IRQ
        ISR.setVecMask VDC_VEC

        ;................................
        ;Clear map
        jsr ClearScreen.64x32


        ;................................
        ;Initialize button states and callbacks
        call Gamepad.Init
        call Controls.Init
        call Input.Init
        MOVE.w #Pressed.b1,     <Button.Callback.b1
        MOVE.w #Pressed.b2,     <Button.Callback.b2
        MOVE.w #Pressed.start,  <Button.Callback.start
        MOVE.w #Pressed.select, <Button.Callback.select
        MOVE.w #Pressed.up,     <Button.Callback.up
        MOVE.w #Pressed.down,   <Button.Callback.down
        MOVE.w #Pressed.left,   <Button.Callback.left
        MOVE.w #Pressed.right,  <Button.Callback.right


        MOVE.w #(64), <RCRline
        VDC.reg RCR , <RCRline
        MOVE.w #(200+64), <RCRline2
        MOVE.b #$02, <rcr_offset


        MOVE.w #$00cf, VDR_lines
        MOVE.w #$0023, VDE_lines
        MOVE.b #$0F,   VSR_lines

        ;................................
        ;start the party
        Interrupts.enable

        PRINT_STR_i "Press A to enable test. ",2,1
        PRINT_STR_i "Press B to stop test. ",2,2
        PRINT_STR_i "Up/Down: VSR : ",2,3
        PRINT_BYTEhex_a_q VSR_lines
        PRINT_STR_i "start/select: RCR line2: ",2,4
        PRINT_HEX_nibble_lo_a <RCRline2+1
        PRINT_BYTEhex_a_q <RCRline2
        PRINT_STR_i "Left/Right: VDR, VDE: ",2,5
        PRINT_BYTEhex_a_q VDR_lines+1
        PRINT_BYTEhex_a_q VDR_lines
        PRINT_Space_a
        PRINT_CHAR_a_q #'/'
        PRINT_Space_a
        PRINT_BYTEhex_a_q VDE_lines+1
        PRINT_BYTEhex_a_q VDE_lines

main_loop:

        WAITVBLANK

        PRINT_STR_i "Up/Down: VSR : ",2,3
        PRINT_BYTEhex_a_q VSR_lines
        PRINT_STR_i "start/select: RCR line2: ",2,4
        PRINT_HEX_nibble_lo_a <RCRline2+1
        PRINT_BYTEhex_a_q <RCRline2
        PRINT_STR_i "Left/Right: VDR, VDE: ",2,5
        PRINT_BYTEhex_a_q VDR_lines+1
        PRINT_BYTEhex_a_q VDR_lines
        PRINT_Space_a
        PRINT_CHAR_a_q #'/'
        PRINT_Space_a
        PRINT_BYTEhex_a_q VDE_lines+1
        PRINT_BYTEhex_a_q VDE_lines

        call Gamepad.READ_IO.single_controller
        call Controls.ProcessInput
        call Input.Callbacks


      jmp main_loop


;Main end
;//...................................................................

;Some sub funcs

Pressed.left:
    SUB.w #$01, VDR_lines
    ADD.w #$01, VDE_lines
    VDC.reg VDR  , VDR_lines
    VDC.reg VDE  , VDE_lines
    rts

Pressed.right:
    ADD.w #$01, VDR_lines
    SUB.w #$01, VDE_lines
    VDC.reg VDR  , VDR_lines
    VDC.reg VDE  , VDE_lines
    rts


Pressed.up:
    dec VSR_lines
    ADD.w #$01, VDE_lines
    st0 #VSR
    lda #$02
    sta $0002
    lda VSR_lines
    sta $0003
    VDC.reg VDE  , VDE_lines
    rts


Pressed.down:
    inc VSR_lines
    SUB.w #$01, VDE_lines
    st0 #VSR
    lda #$02
    sta $0002
    lda VSR_lines
    sta $0003
    VDC.reg VDE  , VDE_lines
    rts


Pressed.b2:
    MOVE.w #(BG_ON|SPR_ON|VINT_ON|HINT_ON), disp
    rts


Pressed.b1:
    MOVE.w #(BG_OFF|SPR_OFF|VINT_ON|HINT_ON), disp
    rts


Pressed.start:
    ADD.w #$01, <RCRline2
    rts


Pressed.select:
    SUB.w #$01, <RCRline2
    rts


;//...................................................................



;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;

;....................................
    .code
    .bank $02, "Subcode 1"
    .org $8000
;....................................

  IncludeBinary Font.cell, "../base_func/video/print/font.dat"

Font.pal: .db $00,$00,$33,$01,$ff,$01,$ff,$01,$ff,$01,$ff,$01,$ff,$01,$f6,$01
Font.pal.size = sizeof(Font.pal)

    ;// Support files for MAIN



;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;





