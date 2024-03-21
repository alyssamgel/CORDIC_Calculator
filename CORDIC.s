#include <xc.inc>

global cordic_setup, cordic_loop, return_sin, return_cosine, load_z0

psect udata_acs
x0:         ds 1
x1:         ds 1
y0:         ds 1
y1:         ds 1
z0:         ds 1
z1:         ds 1
sigma:      ds 1
iter_down:  ds 1
iter_up:    ds 1
count:      ds 1

psect data
tan_array:
    db 128, 75, 39, 20, 10, 5, 2, 1


psect cordic_code, class=CODE

cordic_setup:
    movlw   0x0F    
    movwf   iter_down, A
    movlw   0x00
    movwf   y0, A
    movlw   0xFF
    movwf   x0, A
    movlw   0x00
    movwf   iter_up, A
    return
    
load_z0:
    movwf   z0, A
    return 

cordic_loop:  
    call    find_sigma_j
    call    update_x
    call    update_y
    call    update_z
    
    movff   x1, x0, A
    movff   y1, y0, A
    movff   z1, z0, A
    
    incf    iter_up, F, A
    decfsz  iter_down, F, A        ; Loop for 16 iterations
    goto    cordic_loop
    return

update_x:
    movf    iter_up, W, A
    movwf   count, A
    movf    y0, W, A
bitshift_loop_x:
    bcf     STATUS, 0
    rrcf    WREG, F
    decfsz  count, F, A
    goto    bitshift_loop_x
    movwf   y0, A
    btfss   sigma, 7, A
    goto    skip_as_positive_x
    comf    y0, F, A
    incf    y0, F, A
skip_as_positive_x:
    movf    y0, W, A
    movff   x0, x1, A
    subwf   x1, F, A
    return

update_y:
    movf    iter_up, W, A
    movwf   count, A
    movf    x0, W, A
bitshift_loop_y:
    bcf     STATUS, 0
    rrcf    WREG, F
    decfsz  count, F, A
    goto    bitshift_loop_y
    movwf   x0, A
    btfss   sigma, 7, A
    goto    skip_as_positive_y
    comf    x0, F, A
    incf    x0, F, A
skip_as_positive_y:
    movf    x0, W, A
    movff   y0, y1, A
    addwf   y1, F, A
    return

update_z:
    lfsr    1, tan_array
    movf    iter_up, W, A
    addlw   LOW tan_array
    movwf   FSR1L
    movf    POSTINC1, W
    btfsc   sigma, 0, A
    subwf   z0, F, A
    goto    update_z_end
    addwf   z0, F, A
update_z_end:
    return

find_sigma_j:
    btfss   z0, 7, A			; bit test z, +ve or -ve
    movlw   0x00			; If sig < 0 then set #0 to 0
    movlw   0x01			; If sig > 0 then set #0 to 1
    movwf   sigma, A
    return

return_sin:
    movf    y0, W, A      ; Load the y value (sine) into WREG
    return

return_cosine:
    movf    x0, W, A      ; Load the x value (cosine) into WREG
    return


