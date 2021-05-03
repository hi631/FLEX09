CON_BASE        equ		$F200
DSK_BASE        equ		$F210

UART      EQU  $FFD0
RECEV     EQU  UART+1
TRANS     EQU  UART+1
USTAT     EQU  UART
UCTRL     EQU  UART

		ORG		CON_BASE

		FDB		0
		FDB		0
		FDB		INCH 	; Terminal input character without echo
		FDB		INCHE	; Terminal input character with echo
		FDB		INCHEK	; Terminal status check routinestatus check routine
		FDB		OUTCH	; Terminal output routine
		FDB		0	; H2OUT	; FOR DEBUG
                FDB		0	; H4OUT	; FOR DEBUG

		ORG		DSK_BASE
		JMP     >S_READ   
		JMP     >S_WRITE  
		JMP     >S_VERIFY 
		JMP     >S_RESTORE
		JMP     >S_DRIVE  
		JMP     >S_CHKRDY 
		JMP     >S_QUICK  
		JMP     >S_INIT   
		JMP     >S_WARM   
		JMP     >S_SEEKIT 

		NOP
INCH	
		BSR	CONSIN
                RTS
                
INCHE
		BSR	CONSIN
                BSR	PUTCHR
                RTS
                
INCHEK
		BSR	KEYIN
                RTS
                
OUTCH
                BSR	PUTCHR
                RTS

CONSIN    BSR  KEYIN          GET A CHARACTER FROM CONSOLE IN
          BEQ  CONSIN         LOOP IF NO KEY DOWN
          RTS

KEYIN     LDA  USTAT
          BITA #1
          BEQ  NOCHAR
          LDA  RECEV
          ANDA #$7F
KEYINR    RTS
NOCHAR    CLRA
          RTS

PUTCHR    BSR  WAITACIA
          STA  TRANS
          RTS

WAITACIA  PSHS A
WRWAIT    LDA  USTAT
          BITA #2
          BEQ  WRWAIT
          PULS A
          RTS

H1OUT     ADDA #$30
          CMPA #$39
          BLE  H1OUT2
          ADDA #$07
H1OUT2    BSR  PUTCHR
          RTS
H2OUT     PSHS A
          PSHS A
          LSRA
          LSRA
          LSRA
          LSRA
          BSR  H1OUT
          PULS A
          ANDA #$0F
          BSR  H1OUT
          PULS A
          RTS
H4OUT     PSHS D
          PSHS B
          BSR  H2OUT
          PULS A
          BSR  H2OUT
          PULS D
          RTS

SPOUT     LDA  #$20
          BSR  PUTCHR
          RTS
CROUT     LDA  #$0D
          BSR  PUTCHR
          RTS

PUTSTR    LDA  0,X
          BNE  PUTSTR2
          RTS
PUTSTR2   BSR  PUTCHR
          LEAX  1,X
          BRA  PUTSTR

**********************************************
* FDD R/W
**********************************************
S_READ   
*		PSHS	D,X
*		LDX	#MS_READ
*                JSR	PUTSTR
*                PULS	X,D
*                PSHS	D,X
*                JSR	H4OUT		; TRACK SECTER   ADR=TRAC(A)*36+SECT(B)-1 BS=256
*                PULS	X,D
                PSHS	D,X
                JSR     SDREAD
                PULS	X,D
*                JSR     DUMPEX
                CLRA
                RTS
MS_READ		FCC	"[S_READ]"
		FCB     $00
S_WRITE  
*		PSHS	X
*		LDX	#MS_WRITE
*                JSR	PUTSTR
*                PULS	X
                PSHS	D,X
                JSR     SDWRITE
                PULS	X,D
                CLRA
                RTS
MS_WRITE	FCC	"[S_WRITE]"
		FCB     $00
S_VERIFY 
*		PSHS	X
*		LDX	#MS_VERIFY
*                JSR	PUTSTR
*                PULS	X
                CLRA
                RTS
MS_VERIFY	FCC	"[S_VERIFY]"
		FCB     $00
S_RESTORE
		PSHS	X
		LDX	#MS_RESTORE
                JSR	PUTSTR
                PULS	X
                RTS
MS_RESTORE	FCC	"[S_RESTORE]"
		FCB     $00
S_DRIVE  
*		PSHS	X
*		LDX	#MS_DRIVE
*                JSR	PUTSTR
*                PULS	X
                JSR	SDSELDRV
                RTS
MS_DRIVE	FCC	"[S_DRIVE]"
		FCB     $00
S_CHKRDY 
*		PSHS	X
*		LDX	#MS_CHKRDY
*                JSR	PUTSTR
*                PULS	X
		CLRA
                RTS
S_CHKDRV	LDA 3,X  		; a = DRIVE.NO
                CMPA #3  
                BGT S_CHKNODRV
                CLRA
                RTS
S_CHKNODRV      CLRB
                ADDB #$0F        ERROR. Z=0
                ORCC #$01               C=1
                RTS
MS_CHKRDY	FCC	"[S_CHKRDY]"
		FCB     $00
S_QUICK  
		PSHS	X
		LDX	#MS_QUICK
                JSR	PUTSTR
                PULS	X
                RTS
MS_QUICK	FCC	"[S_QUICK]"
		FCB     $00
S_INIT   
*		PSHS	X
*		LDX	#MS_INIT
*                JSR	PUTSTR
*                PULS	X
                CLRA
                RTS
MS_INIT		FCC	"[S_INIT]"
		FCB     $00
S_WARM   
*		PSHS	X
*		LDX	#MS_WARM
*                JSR	PUTSTR
*                PULS	X
                CLRA
                RTS
MS_WARM		FCC	"[S_WARM]"
		FCB     $00
S_SEEKIT 
*		PSHS	X
*		LDX	#MS_SEEKIT
*                JSR	PUTSTR
*                PULS	X
		CLRA			; Z=1
                RTS
MS_SEEKIT	FCC	"[S_SEEKIT]"
		FCB     $00


MONCMD    RMB  1
MONAD     RMB  2
MONAD2    RMB  2
MONAD3    RMB  2
MONWK0    RMB  1
MONWK1    RMB  1
HLOADAD   RMB  2
HLOADDL   RMB  1
HLOADWK   RMB  1
HNINPWK   RMB  1

DUMPEX    PSHS X,D
          JSR CROUT
          STX  MONAD2
          LDB  #8
          STB  MONWK0
DUMPLP2   LDX  MONAD2
          LDD  MONAD2
          JSR  H4OUT
          JSR  SPOUT
          LDB  #16
DUMPLP3   LDA  0,X
          LEAX 1,X
          JSR  H2OUT
          JSR  SPOUT
          DECB
          BNE  DUMPLP3
          STX  MONAD2
          JSR CROUT
          DEC  MONWK0
          LDB  MONWK0
          BNE  DUMPLP2
          PULS D,X
          RTS

*-----------------------------------
* SD ACCESS
*-----------------------------------
* MULTICOMP SDCARD CONTROL REGISTERS
SDDATA         EQU $FFD8
SDCTL          EQU $FFD9
SDLBA0         EQU $FFDA
SDLBA1         EQU $FFDB
SDLBA2         EQU $FFDC

SDDRV          FCB $00, $00, $00 CURRENT DRIVE
SDTMP          FCB $00, $00, $00
SDBUFP         RMB 2
SDFCBTMP       RMB 4
SDRWBUF        RMB 256           READ/WRITE.BUF LO
SDRWBUF2       RMB 256                          HI
SECPOS         FCB $00           SECTER.POSITION 0/1 = 0-255/256-511

*-----------------------------------------------------
* READ ONE SECTOR A:TRACK B:SECTOR X:WRITE.ADR(256BYTE)
* B:ERROR CODE(Z=1 NO ERROR, Z=0 ERROR
*------------------------------------------------------
SDREAD         LBSR LDSDADRS     T,S -> BLOCK, LD HW REGISTERS

* WAIT FOR PREVIOUS COMMAND (IF ANY) TO COMPLETE
RDBIZR         LDA SDCTL
               CMPA #$80
               BNE RDBIZR

* ISSUE THE READ COMMAND TO THE SDCARD CONTROLLER
               CLRA
               STA  SDCTL

* TRANSFER 512 BYTES, WAITING FOR EACH IN TURN. ONLY WANT 256 OF THEM - DISCARD THE REST
               LDA  SECPOS
               BITA #1
               BNE  SDRBHI
SDRBLO         CLRB             BLOCK(0-255) READ
               BSR  SDRBIZ
               LDX  #SDRWBUF
               BSR  SDRBIZ
               CLRA             SET Z TO INDICATE SUCCESSFUL COMPLETION
               RTS
SDRBHI         CLRB             BLOCK(256-511) READ
               STX  SDBUFP
               LDX  #SDRWBUF
               BSR  SDRBIZ
               LDX  SDBUFP
               BSR  SDRBIZ
               CLRA             SET Z TO INDICATE SUCCESSFUL COMPLETION
               RTS

SDRBIZ         LDA SDCTL
               CMPA #$E0
               BNE SDRBIZ       BYTE NOT READY
               LDA SDDATA       GET BYTE
               STA ,X+          STORE IN SECTOR BUFFER
               DECB
               BNE SDRBIZ       NEXT
               RTS

*-----------------------------------------------------
* WEITE ONE SECTOR A:TRACK B:SECTOR X:READ.ADR(256BYTE)
* READ(512B) -> UPDATE(0-255/256-511) -> WRITE(512B)
* B:ERROR CODE(Z=1 NO ERROR, Z=0 ERROR
*------------------------------------------------------
SDWRITE        LBSR LDSDADRS     T,S -> BLOCK, LD HW REGISTERS

* WAIT FOR PREVIOUS COMMAND (IF ANY) TO COMPLETE
WRBIZR         LDA SDCTL
               CMPA #$80
               BNE  WRBIZR
* READ COMMAND TO THE SDCARD CONTROLLER
               CLRA
               STA  SDCTL
* READ 512B TO TEMP.BUF
               STX  SDBUFP
               LDX  #SDRWBUF
               CLRB
               BSR  SDRBIZ
               LDX  #SDRWBUF2
               BSR  SDRBIZ
* UPDATE WRITE.DATA
               PSHS Y
               LDX  SDBUFP
               LDA  SECPOS
               BITA #1
               BNE  WUPDTHI
WUPDTLO        LDY  #SDRWBUF
               BRA  WUPDT
WUPDTHI        LDY  #SDRWBUF2
WUPDT          
               CLRB
WUPDTLP        LDA  ,X+
               STA  ,Y+
               DECB
               BNE  WUPDTLP
               PULS Y
* WRITE 512B
WRBIZW         LDA SDCTL
               CMPA #$80
               BNE WRBIZW
* WRITED COMMAND TO THE SDCARD CONTROLLER
               LDA  #1
               STA  SDCTL
* WRITE 512B FORM TEMP.BUF
               CLRB
               LDX  #SDRWBUF
               BSR  SDWBIZ
               LDX  #SDRWBUF2
               BSR  SDWBIZ
               LDX  SDBUFP
               CLRA
               RTS
*
SDWBIZ         LDA SDCTL
               CMPA #$A0
               BNE SDWBIZ       SPACE NOT AVAILABLE
               LDA ,X+          GET BYTE FROM BUFFER
               STA SDDATA       STORE TO SD
               DECB
               BNE SDWBIZ       NEXT
               RTS
*
*----------------------------------------------------------
LDSDADRS       PSHS X           PRESERVE IT
               LDX  #SDTMP      SCRATCH AREA FOR COMPUTATION

* ADD IN THE "+B - 1" PART TO THE IMAGE BASE OF THE CURRENT DRIVE
               SUBB #1          SECTOR->OFFSET. EG: SECTOR 1 IS AT OFFSET 0
               STB  SECPOS
               LSRB             SECTER(B) = SECTE / 2
               ADDB SDDRV+2     ADD SECTOR OFFSET TO LBA0 OF IMAGE BASE, CURRENT DRIVE
               STB  ,X+         STORE IN SCRATCH SPACE
               LDB  #0
               ADCB SDDRV+1     RIPPLE CARRY TO LBA1 OF IMAGE BASE, CURRENT DRIVE
               STB  ,X+         AND STORE
               LDB  #0
               ADCB SDDRV+0     RIPPLE CARRY TO LBA2 OF IMAGE BASE, CURRENT DRIVE
               STB  ,X          AND STORE
               LEAX -2,X        X BACK TO START OF BUFFER
               
* ADD IN THE "A*72" PART AND STORE TO WRITE-ONLY HARDWARE REGISTERS
* [NAC HACK 2015May26] MAYBE PUT THE 72 IN RAM SO WE CAN SUPPORT OTHER GEOMETRIES/DD-DISKS
* 1010:Adr(16:9   7:0 )  1011:Adr(24:17 15:8 )  1100:Adr(31:25 23:16)
               LDB  #18         #72
               MUL  A B
               ADDB ,X+         ADD LS BYTE IN B TO LBA0+SECTOR
               STB  SDLBA0      LS BYTE DONE
               ADCA ,X+         ADD MS BYTE IN A TO LBA1+CARRY
               STA  SDLBA1      AND STORE
               LDA  #0
               ADCA ,X          RIPPLE CARRY TO LAST BYTE
               STA  SDLBA2      AND STORE
               PULS X
               RTS

*--------------------------------------------------------
* SELECT THE SPECIFIED DRIVE.  X: FCB ADDRESS (3,X CONTAINS THE DRIVE NUMBER, 0-3)
* EXIT ERROR:   Z=0, C=1, B=$0F (NON-EXISTENT DRIVE)
*DRIVE(0-3) SD.OFFSET (diskdef cpm86-720 ?)
SDDRV0         FCB $00, $00, $00
SDDRV1         FCB $00, $08, $00
SDDRV2         FCB $00, $10, $00
SDDRV3         FCB $00, $18, $00
SDSELDRV
               LDA 3,X          DRIVE NUMBER
               CMPA #3          ENSURE IT'S <4
               BGT NODRV        NO GOOD!

               PSHS X           SAVE FCB
               LDX #SDDRV0      LIST OF DRIVE OFFSETS
               LDB #3           SIZE OF TABLE ENTRY
               MUL              OFFSET FROM SDDRV0
*                               RESULT IS 0-12 SO MUST BE WHOLLY IN B
               fcb $3A		;ABX              ADDRESS OF LBA2 FOR REQUESTED DRIVE
               LDA 0,X          GET LBA2 VALUE
               CMPA #$FF
               BEQ NODRV1       DRIVE NOT AVAILABLE
               STA SDDRV+0      STORE LBA2
               LDA 1,X          GET LBA1 VALUE
               STA SDDRV+1      STORE LBA1
               LDA 2,X          GET LBA0 VALUE
               STA SDDRV+2      STORE LBA0
               PULS X           RESTORE FCB
               CLRA             Z=1, C=0 TO INDICATE SUCCESSFUL COMPLETION
               RTS

NODRV1         PULS X           RESTORE FCB
NODRV          CLRB
               ADDB #$0F        ERROR. Z=0
               ORCC #$01               C=1
               RTS

