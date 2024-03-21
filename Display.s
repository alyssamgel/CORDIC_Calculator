#include <xc.inc>
    
global	multiply_8x8, multiply_16x16, convert_to_decimal, ans_h, ans_l, split
;extrn	ans
    
psect udata_acs:
    ans:     ds 1
    ans_h:   ds 1
    ans_l:   ds 1

    ARG1L:   ds 1
    ARG2L:   ds 1
    ARG1H:   ds 1
    ARG2H:   ds 1
    ARG1M:   ds 1
    
    RES0:    ds 1
    RES1:    ds 1
    RES2:    ds 1
    RES3:    ds 1
    
    HB:	     ds 1
    LB:	     ds 1
    
psect	display_code,class=CODE
    
split:
    movwf   ans
    movf    ans, ans_l
    rlncf   ans_l, F
    rlncf   ans_l, F
    rlncf   ans_l, F
    rlncf   ans_l, F		    ; shift to left by 4 bits 
    
    movf    ans, W
    andwf   ans_h, 1
    
    return 
    

multiply_8x8:
    movf    ARG1L, W  
    mulwf   ARG2L		    ; ARG1 * ARG2 ->  PRODH:PRODL
    
    return
    
multiply_16x16:
    movf    ARG1L, W 
    mulwf   ARG2L		    ; ARG1L * ARG2L->  PRODH:PRODL 
    movff   PRODH, RES1 
    movff   PRODL, RES0 
    
    movf    ARG1H, W 
    mulwf   ARG2H		    ; ARG1H * ARG2H-> PRODH:PRODL 
    movff   PRODH, RES3 
    movff   PRODL, RES2 
    
    movf    ARG1L, W 
    mulwf   ARG2H		    ; ARG1L * ARG2H-> PRODH:PRODL 
    movf    PRODL, W 
    addwf   RES1, F		    ; Add cross products
    movf    PRODH, W 
    addwfc  RES2, F 
    clrf    WREG  
    addwfc  RES3, F  
    
    movf    ARG1H, W  
    mulwf   ARG2L		    ; ARG1H * ARG2L-> PRODH:PRODL 
    movf    PRODL, W  
    addwf   RES1, F		    ; Add cross products
    movf    PRODH, W  
    addwfc  RES2, F  
    clrf    WREG  
    addwfc  RES3, F  
    
    return 
    
multiply_24x8:
    movf    ARG1L, W 
    mulwf   ARG2L		    ; ARG1L * ARG2L->  PRODH:PRODL 
    movff   PRODH, RES1  
    movff   PRODL, RES0  
    
    movf    ARG1M, W
    mulwf   ARG2L
    movff   PRODH, RES3
    movff   PRODL, RES2
    
    movf    ARG1H, W
    mulwf   ARG2L
    movf    PRODL, W
    addwfc  RES1, F
    movf    PRODH, W
    addwfc  RES2, F
    clrf    WREG
    addwfc  RES3, F
    
    return 
    
set_new:
    movff   RES0, ARG1L
    movff   RES1, ARG1H
    movff   RES2, ARG1M
    
    movlw   0x0A		    ; multiplying by 10
    movwf   ARG2L
    call    multiply_24x8
    
    return 
    
    
convert_to_decimal:
    movff   ans_h, ARG1H
    movff   ans_l, ARG1L
    
    movlw   0x05		   ; value of multiplier, k
    movwf   ARG2H
    movlw   0xBD
    movwf   ARG2L
    
    call    multiply_16x16
    movff   RES3, HB
    rlncf   HB, F
    rlncf   HB, F
    rlncf   HB, F
    rlncf   HB, F		   ; shift to left by 4 bits 
    
    call    set_new
    movf    RES3, W
    andwf   HB, 1
    
    call    set_new
    movff   RES3, LB
    rlncf   LB, F
    rlncf   LB, F
    rlncf   LB, F
    rlncf   LB, F		   ; shift to left by 4 bits 
    
    call    set_new
    movf    RES3, W
    andwf   LB, 1
    
    return 
    