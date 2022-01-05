
Input.Init:

    MOVE.w #.no_callback, Button.Callback.b1
    MOVE.w #.no_callback, Button.Callback.b2
    MOVE.w #.no_callback, Button.Callback.start
    MOVE.w #.no_callback, Button.Callback.select
    MOVE.w #.no_callback, Button.Callback.up
    MOVE.w #.no_callback, Button.Callback.down
    MOVE.w #.no_callback, Button.Callback.left
    MOVE.w #.no_callback, Button.Callback.right


.no_callback
    rts

Input.Callbacks:

.stand.check.b1
        lda input_state.buttons
        and #control.b1.mask
        cmp #control.b1.pressed
      bne .stand.check.b2
        jmp [Button.Callback.b1]
.stand.check.b2
        lda input_state.buttons
        and #control.b2.mask
        cmp #control.b2.pressed
      bne .stand.check.st
        jmp [Button.Callback.b2]
.stand.check.st
        lda input_state.buttons
        and #control.st.mask
        cmp #control.st.held
      bne .stand.check.sl
        jmp [Button.Callback.start]
.stand.check.sl
        lda input_state.buttons
        and #control.sl.mask
        cmp #control.sl.held
      bne .check.directions
        jmp [Button.Callback.select]


.check.directions
        lda input_state.directions
.stand.check.up
        bit #control.up.held
      beq .stand.check.dn
        jmp [Button.Callback.up]
.stand.check.dn
        bit #control.dn.held
      beq .stand.check.lf
        jmp [Button.Callback.down]
.stand.check.lf
        bit #control.lf.held
      beq .stand.check.rh
        jmp [Button.Callback.left]
.stand.check.rh
        bit #control.rh.held
      beq .out
        jmp [Button.Callback.right]

.out
    rts

