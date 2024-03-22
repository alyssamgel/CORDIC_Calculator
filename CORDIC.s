#include <xc.inc>

global cordic_setup, cordic_loop, return_sin, return_cosine, load_z0

psect udata_acs
x0:		ds 1
x1:		ds 1
y0:		ds 1
y1:		ds 1
z0:		ds 1
z1:		ds 1
sigma:		ds 1
iter_down:	ds 1
iter_up:	ds 1
count:		ds 1
counter:	ds 1
temp:		ds 1
    
    tan_address   EQU 0x70

psect data
tan_array:
    db 0x80, 0x4B, 0x27, 0x14, 0x0A, 0x05, 0x02, 0x01
    tan_array_len   EQU	8
    align    2
   


psect cordic_code, class=CODE

cordic_setup:
    movlw   0x0F    
    movwf   iter_down, A
    movlw   0x00
    movwf   y0, A
    movwf   iter_up, A
    movwf   z0, A
    movwf   x1, A
    movwf   y1, A
    movwf   z1, A
    movwf   temp, A
    movlw   0xFF
    movwf   x0, A
    
    start: 	
	lfsr	1, tan_address		; Load FSR0 with address in RAM	
	movlw	low highword(tan_array)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(tan_array)		; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(tan_array)		; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	tan_array_len		; bytes to read
	movwf 	counter, A		; our counter register
    loop: 	
	tblrd*+				; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC1	; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	loop			; keep going until finished
    return
    
load_z0:
    movwf   z0, A
    lfsr    1, tan_address		; Load tan_array into fsr 1
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
    decfsz  iter_down, F, A        ; Loop for 8 iterations
    goto    cordic_loop
    return

update_x:
    movff   iter_up, count, A
    movlw   0x01
    addwf   count, A
    movf    y0, W, A
bitshift_loop_x:
    bcf     STATUS, 0
    rrcf    WREG, W
    decfsz  count, F, A
    goto    bitshift_loop_x
    movwf   temp, A				; move shifted y0 into temp
    btfss   sigma, 0, A
    goto    skip_as_positive_x
    comf    temp, F, A
    incf    temp, F, A
skip_as_positive_x:
    movff   x0, x1, A
    movf    temp, W, A
    subwf   x1, F, A
    return

update_y:
    movff   iter_up, count, A
    movlw   0x01
    addwf   count, A
    movf    x0, W, A
bitshift_loop_y:
    bcf     STATUS, 0
    rrcf    WREG, W
    decfsz  count, F, A
    goto    bitshift_loop_y
    movwf   temp, A
    btfss   sigma, 0, A
    goto    skip_as_positive_y
    comf    temp, F, A
    incf    temp, F, A
skip_as_positive_y:
    movff   y0, y1, A
    movf    temp, W, A
    addwf   y1, F, A
    return

update_z:
    movff   z0, z1, A
    movf    iter_up, W, A
    addlw   FSR1L
    movf    POSTINC1, W
    btfsc   sigma, 0, A
    goto    pos_sigma
    subwf   z1, F, A
    goto    update_z_end
    
pos_sigma:
    addwf   z1, F, A
    
update_z_end:
    return

find_sigma_j:
    btfss   z0, 7, A			; bit test z, +ve or -ve
    goto    neg_sigma
    movlw   0x01			; If sig < 0 then set #0 to 1
    movwf   sigma, A
    return
    
    neg_sigma:
    movlw   0x00			; If sig > 0 then set #0 to 0
    movwf   sigma, A
    return

return_sin:
    movf    y0, W, A      ; Load the y value (sine) into WREG
    return

return_cosine:
    movf    x0, W, A      ; Load the x value (cosine) into WREG
    return


