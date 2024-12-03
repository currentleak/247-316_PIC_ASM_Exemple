;   This file is a basic code template for assembly code generation   *
;   on the PICmicro PIC16F88. This file contains the basic code       *
;   building blocks to build upon.                                    *
;                                                                     *
;   If interrupts are not used all code presented between the ORG     *
;   0x004 directive and the label main can be removed. In addition    *
;   the variable assignments for 'w_temp' and 'status_temp' can       *
;   be removed.                                                       *
;                                                                     *
;   Refer to the MPASM User's Guide for additional information on     *
;   features of the assembler (Document DS33014).                     *
;                                                                     *
;   Refer to the respective PICmicro data sheet for additional        *
;   information on the instruction set.                               *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Filename:	    xxx.asm                                           *
;    Date:                                                            *
;    File Version:                                                    *
;                                                                     *
;    Author:                                                          *
;    Company:                                                         *
;                                                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Files required:                                                  *
;                                                                     *
;                                                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;                                                                     *
;                                                                     *
;                                                                     *
;                                                                     *
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
  
  vReceive	    ; variable pour la reception d'un caractere sur le port UART
  vFlagReceive	    ; flag pour indiquer une réception sur le port série
  
  vDelai1ms                    ; Variable pour le délai de 1ms.
  vDelai5ms                    ; Variable pour le délai de 5ms.
  
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
     
     ; Config pour Interrupt
     bsf    INTCON, GIE
     bsf    INTCON, PEIE
     BANK1
     bsf    PIE1, RCIE
     BANK0
     bcf    vFlagReceive, 0
    
LoopForever
     call   Delai5ms
    
     btfss  vFlagReceive, 0
     goto   LoopForever
     
     movf   vReceive, W
     call   Tx232
     call   Tx232
     bcf    vFlagReceive, 0
     
     goto   LoopForever	; Repeat forever

;******************************************************************************
;******************************* ROUTINES *************************************
     
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
;Rx232
;    Btfss   PIR1, RCIF       ;Attend de recevoir quelque chose sur 
;    goto    Rx232           ;le port serie.
;Rx232Go                     ;Si recu sur le port serie
;    movfw   RCREG        
;    movwf   vReceive        ;Met le caractère reçu dans vReceive
;    return
    
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
     bcf     INTCON, GIE        ; Désactive les interruptions        
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
     
;****************************** Interruption **********************************
Interruption
    movwf     w_temp         ; save off current W register contents
    movf      STATUS,w       ; move STATUS register into W register
    movwf     status_temp    ; save off contents of STATUS register
    movf      PCLATH,W       ; move PCLATH register into W register
    movwf     pclath_temp    ; save off contents of PCLATH register

; isr code can go here or be located as a call subroutine elsewhere
    movfw   RCREG        
    movwf   vReceive        ;Met le caractère reçu dans vReceive
    bsf	    vFlagReceive,0

    movf      pclath_temp,w  ; retrieve copy of PCLATH register
    movwf     PCLATH         ; restore pre-isr PCLATH register contents
    movf      status_temp,w  ; retrieve copy of STATUS register
    movwf     STATUS         ; restore pre-isr STATUS register contents
    swapf     w_temp,f
    swapf     w_temp,w       ; restore pre-isr W register contents
    retfie                   ; return from interrupt

; fin de la routine Interruption-----------------------------------------------



; initialize eeprom locations

	ORG	0x2100
	DE	0x00, 0x01, 0x02, 0x03


	END                       ; directive 'end of program'

