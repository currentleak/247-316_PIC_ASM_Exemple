;   This file is a basic code template for assembly code generation   *
;   on the PICmicro PIC16F88. This file contains the basic code       *
;   building blocks to build upon.                                    *
;**********************************************************************
;    Filename:	    xxx.asm                                           *
;    Date:                                                            *
;    File Version:                                                    *
;    Author:                                                          *
;    Company:                                                         *
;**********************************************************************
;    Files required:                                                  *
;                                                                     *
;**********************************************************************
;    Notes:                                                           *
;    X+ --> RA6, X- --> RA0                                           *
;    Y+ --> RA1, Y- --> RA7                                           *
;**********************************************************************
     LIST      p=16f88         ; Liste des directives du processeur.
     #include <p16F88.inc>     ; Définition des registres spécifiques au CPU.

     errorlevel  -302          ; Retrait du message d'erreur 302.

     __CONFIG    _CONFIG1, _CP_OFF & _CCP1_RB0 & _DEBUG_OFF & _WRT_PROTECT_OFF & _CPD_OFF & _LVP_OFF & _BODEN_ON & _MCLR_ON & _PWRTE_ON & _WDT_OFF & _INTRC_IO

     __CONFIG    _CONFIG2, _IESO_OFF & _FCMEN_OFF
; '__CONFIG' directive is used to embed configuration word within .asm file.
; The lables following the directive are located in the respective .inc file.
; See data sheet for additional information on configuration word settings.
;******************************************************************************
; Constants
;#define _XTAL_FREQ 4000000     ; 4 MHz clock frequency
; Baud rate settings
;#define BAUD_RATE 9600
;#define SPBRG_VALUE ((_XTAL_FREQ / (16 * BAUD_RATE)) - 1)

;***********************************DEFINES************************************
#define      BANK0             bcf   STATUS,RP0;
#define      BANK1             bsf   STATUS,RP0;

;***********************************KIT-PIC************************************
#define      SW1               PORTB,6
#define      SW2               PORTB,7
#define      SW3               PORTA,7
#define      DEL1              PORTB,3
#define      DEL2              PORTB,4
;*************************************I2C**************************************
#define      SCL               PORTB,0
#define      SDA               PORTB,1

;***** VARIABLE DEFINITIONS
w_temp        EQU     0x71        ; variable used for context saving 
status_temp   EQU     0x72        ; variable used for context saving
pclath_temp   EQU     0x73	  ; variable used for context saving

;VosVariables  EQU     0x20       ; Mettre ici vos Variables
  CBLOCK  0x20
  
  adc_result_high  ; High byte of ADC result
  adc_result_low   ; Low byte of ADC result
  channel_index    ; Channel index (0 to 3)
  
  vValH		    ; variable pour la conversion Hex to ASCII
  vValL
  vValA
  
  vDelai1ms                    ; Variable pour le délai de 1ms.
  vDelai5ms                    ; Variable pour le délai de 5ms.
  vDelai1s                     ; Variable pour le délai de 1s.

  endc
;*************************VECTEUR DE RESET*************************************
     ORG     0x000             ; Processor reset vector
     clrf    PCLATH            ; Page 0 (a cause du BootLoader)
     goto    main              ; 

;***********************VECTEUR D'INTERRUPTION*********************************    
     ORG     0x004             ; Interrupt vector location
     goto    Interruption

main
     call InitPic
     call InitRS232
LoopForever
    call LireAxeX
    movf    adc_result_high, W
    call    Tx232         ; Send high byte
;    movf    adc_result_low, W
;    call    Tx232         ; Send low byte

    call LireAxeY
    movf    adc_result_high, W
    call    Tx232         ; Send high byte
;    movf    adc_result_low, W
;    call    Tx232         ; Send low byte

     call Delai5ms
     goto LoopForever	; Repeat forever

;******************************************************************************
;******************************* ROUTINES *************************************

; ****************************** LIRE AXE Y *******************************
LireAxeY
    movlw   b'10000001'       ; Fosc/32, select channel 0, ADON
    movwf   ADCON0
    BANK1
    movlw   b'01111101'      ; set RA1 et RA7 en sortie  
    movwf   TRISA	     ; RA0 et RA6 en entrée
    BANK0
    bsf	    PORTA,1	    ; mettre 1 sur RA1 
    bcf	    PORTA,7	    ; et mettre 0 sur RA7
    BANK1
    movlw  b'00000001'	    ; mettre RA0 en mode analogique
    movf   ANSEL, W
    BANK0
    call Delai100ms
    bsf     ADCON0, GO_DONE   ; Start ADC conversion
Wait_ADC_Y
    btfsc   ADCON0, GO_DONE   ; Wait for conversion complete
    goto    Wait_ADC_Y
    ; Read ADC result
    movf    ADRESH, W         ; Read high byte
    movwf   adc_result_high
    BANK1
    movf    ADRESL, W         ; Read low byte
    movwf   adc_result_low
    BANK0
    return
    
; ****************************** LIRE AXE X *******************************
LireAxeX
    movlw   b'10001001'       ; Fosc/32, select channel 1, ADON
    movwf   ADCON0
    BANK1
    movlw   b'10111110'      ; set RA0 et RA6 en sortie  
    movwf   TRISA	     ; RA1 et RA7 en entrée
    BANK0
    bsf	    PORTA,0	    ; mettre 1 sur RA0 
    bcf	    PORTA,6	    ; et mettre 0 sur RA6
    BANK1
    movlw  b'00000010'	    ; mettre RA1 en mode analogique
    movf   ANSEL, W
    BANK0
    call Delai5ms
    bsf     ADCON0, GO_DONE   ; Start ADC conversion
Wait_ADC_X
    btfsc   ADCON0, GO_DONE   ; Wait for conversion complete
    goto    Wait_ADC_X
    ; Read ADC result
    movf    ADRESH, W         ; Read high byte
    movwf   adc_result_high
    BANK1
    movf    ADRESL, W         ; Read low byte
    movwf   adc_result_low
    BANK0
    return    
     
; ******************* CONVERTIR HEXADECIMAL EN ASCII **************************     
HexEnASCII
     movwf   vValH             ; Place W dans la variable vValH.
     call    WEnASCII          ; Appel de la sous-routine WEnASCII.
     movwf   vValL             ; Place W dans la variable vValL.
     swapf   vValH,w           ; 
     call    WEnASCII          ;
     movwf   vValH             ;
     return                    ;
WEnASCII                       ;
     andlw   0x0F              ;
     movwf   vValA             ; 
     movlw   0x0A              ;
     subwf   vValA,w           ; 
     SKPC                      ;
     goto    Add37             ;
     addlw   0x07              ;
Add37                          ;
     addlw   0x3A              ;
     return	                   ;
     
;*********************************InitRS232************************************
InitRS232
    movlw   b'10010000';     Set reception sur port serie SPEN=CREN = 1
    movwf   RCSTA;       
    BANK1       
    movlw   b'00100100';     Set la transmission sur le port serie
    movwf   TXSTA;       
    movlw   .25;             Set la vitesse a 19200 bds
    movwf   SPBRG;       
    BANK0      
    return
    
;*************************************Rx232************************************
Rx232
    Btfss   PIR1,RCIF       ;Attend de recevoir quelque chose sur 
    goto    Rx232           ;le port serie.
Rx232Go                     ;Si recu sur le port serie
    movfw   RCREG        
    ;movwf   vReceive        ;Met le caractère reçu dans vReceive
    return
    
;*************************************Tx232************************************
Tx232
    btfss   PIR1,TXIF       ;Attend que la fin de la transmission  
    goto    Tx232
    movwf   TXREG           ;Transmet le caractere
    return       
    
;******************************* InitPic **************************************
InitPic
     bcf     STATUS, RP1       ; Pour s'assurer d'être dans les bank 0 et 1 
     BANK1                     ; Select Bank1        
     bcf     INTCON,GIE        ; Désactive les interruptions        
     clrf    ANSEL             ; Désactive les convertisseurs reg ANSEL 0x9B        
     movlw   b'01111000'       ; osc internal 8 Mhz
     movwf   OSCCON
     movlw   b'11111111'       ; set port all inputs
     movwf   TRISA             ; PortA en entree         
     movlw   b'11100111'       ; Bits en entrées sauf,
     movwf   TRISB             ; RB3 (Led1), RB4 (Led2) en sortie. 

     ; config ADC
    movlw   b'00000000'       ; Right justified, disabled divide clock, vref=Vdd-Vss
    movwf   ADCON1
    BANK0
     return

;****************************** Delai5us **************************************
Delai5us  
     nop
     nop
     nop
     nop
     nop
     nop
     return
     
;****************************** Delai1ms **************************************
Delai1ms                       ; Delai pour attendre entre la transmission
     movlw   .154;             ; Nombre de fois que l'on veut exécuter  
     movwf   vDelai1ms         ; la routine Delai5us.
LongDelai                      ;
     call    Delai5us          ;      
     decfsz  vDelai1ms,F       ; (154*(5us + 1,5us (3 cycles))) = 1.0ms a 8mHz
     goto    LongDelai         ;
     return  
     
;****************************** Delai5ms **************************************
Delai5ms                       ; Delai de 5msec.
     movlw   .5;               
     movwf   vDelai5ms
LongDelai5ms
     call    Delai1ms                
     decfsz  vDelai5ms,F       ; (5*(1ms + 1,5us (3 cycles))) = 5.0ms a 8mHz
     goto    LongDelai5ms
     return

;******************************* Delai1s **************************************
Delai100ms                        ; Delai de 100msec.
     movlw   .20;               
     movwf   vDelai1s
LongDelai100ms
     call    Delai5ms                
     decfsz  vDelai1s,F       
     goto    LongDelai100ms
     return

;******************************* Delai1s **************************************
Delai1s                        ; Delai de 1sec.
     movlw   .200;               
     movwf   vDelai1s
LongDelai1s
     call    Delai5ms                
     decfsz  vDelai1s,F       
     goto    LongDelai1s
     return
     
;****************************** Interruption **********************************
Interruption
;    movwf     w_temp         ; save off current W register contents
;    movf      STATUS,w       ; move STATUS register into W register
;    movwf     status_temp    ; save off contents of STATUS register
;    movf      PCLATH,W       ; move PCLATH register into W register
;    movwf     pclath_temp    ; save off contents of PCLATH register

; isr code can go here or be located as a call subroutine elsewhere

;    movf      pclath_temp,w  ; retrieve copy of PCLATH register
;    movwf     PCLATH         ; restore pre-isr PCLATH register contents
;    movf      status_temp,w  ; retrieve copy of STATUS register
;    movwf     STATUS         ; restore pre-isr STATUS register contents
;    swapf     w_temp,f
;    swapf     w_temp,w       ; restore pre-isr W register contents
    retfie                   ; return from interrupt
; fin de la routine Interruption-----------------------------------------------

; initialize eeprom locations

	ORG	0x2100
	DE	0x00, 0x01, 0x02, 0x03


	END                       ; directive 'end of program'

