ROMBASE   EQU  $9000          MONITOR $9000=RUN.RAM  $A000=RUN.ROM(->RAM)

UART      EQU  $FFD0
RECEV     EQU  UART+1
TRANS     EQU  UART+1
USTAT     EQU  UART
UCTRL     EQU  UART
SYSCTRL   EQU  $FFFF
RTS_LOW   EQU  $15

BS        EQU  8              BACKSPACE
CR        EQU  $D             ENTER KEY
ESC       EQU  $1B            ESCAPE CODE
SPACE     EQU  $20            SPACE (BLANK)

          ORG  $200          MONITOR WORK
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

          ORG  ROMBASE
          JMP  BSTART           BASIC ENTRY
RSTART    LDS  #$1EE		RESET START
          LDX  #ROMBASE
          LDA  #$5A
          STA  -1,X
          CMPA -1,X		IS RAM ?
          BNE  MONI
RSTARTLP  LDA  0,X		COPY ROM -> RAM
          STA  0,X
          LEAX 1,X
          CMPX #ROMBASE+$2000
          BNE  RSTARTLP
BSTART    
          PSHS X,Y,B,A
          LDA  #$81
          STA  SYSCTRL		DISALE BASIC.ROM
          BSR  MONI
          LDA  #$00
          STA  SYSCTRL		ENABLE BASIC.ROM
          PULS A,B,Y,X
          CLRA
          RTS

DLYT      CLRA
DLYA      DECA
          BNE  DLYA
          RTS
INITACIA  LDA  #3             RESET ACIA
          STA  UCTRL
          BSR  DLYT
          LDA  #RTS_LOW       DIV16 CLOCK -> 7372800 / 4 / 16 = 115200
          STA  UCTRL
          BSR  DLYT
          RTS

MONI      BSR  INITACIA
          LDX  #INITMSG
          JSR  STROUT
          
MONI2     LDA  #$3E		>
          JSR  PUTCHR
          JSR  CONSINWE
          STA  MONCMD
          CMPA #$0D
          BEQ  MONI
          JSR  HNINP		MONAD <- INPUT.HEX
          
MONI3     LDA  MONCMD
          CMPA #$44		D = DUMP(D AAAA)
          BNE  MONI4
          JSR  DUMP
          LBRA  MONIE
MONI4     CMPA #$4C		L = LOAD(LOAD HEX)
          BNE  MONI5
          JSR  HLOAD
          BRA  MONIE
MONI5     CMPA #$53		S = SYSTEM(S81 OR S00)
          BNE  MONI6
          LDA  MONAD+1
          STA  SYSCTRL		SET SYS_CTRL
          BRA  MONIE
MONI6     CMPA #$46		F = FILL(F AAAA BBBB DD)
          BNE  MONI7
          JSR  FILLDT
          BRA  MONIE
MONI7     CMPA #$47		G = GO.PRG(G AAAA)
          BNE  MONI8
          LDX  MONAD
          JSR  0,X
          BRA  MONIE
MONI8     CMPA #$52		R = READ(R SDAD MEMAD SDLEN)
          BNE  MONI9
          CLRA
          JSR  SDRWC		SDREAD(256B)
          BRA  MONIE
MONI9     CMPA #$57		W = WRITE(W SDAD MEMAD SDLEN)
          BNE  MONI10
          LDA  #1
          JSR  SDRWC
          BRA  MONIE
MONI10    CMPA #$55		U = UINT.SELECT(U N)
          BNE  MONI11
          LDA  MONAD+1
          LDX  #SDFCBTMP
          STA  3,X		DRIVE.NO
          JSR  SDSELDRV
          LDX  #SDDRV
          LDA  0,X
          JSR  H2OUT
          LDD  1,X
          JSR  H4OUT
          BRA  MONIE
MONI11    CMPA #$42		B = BOOT
          BNE  MONI99
          LDD  #$5001		SD.ADDR = 80T/1S
          STD  MONAD2
          LDD  #$C000		MEM.ADDR = $C000
          STD  MONAD3
          CLR  MONCMD		CMD(READ)
          LDB  #$3F		LOOP.COUNT
          JSR  SDRWCLP
          LDX  #$CD00
          JSR  0,X		JMP FLEX
          BRA  MONIE

MONI99    CMPA #$51		Q
          BNE  MONIE
          RTS
MONIE     JSR  CROUT
          LBRA  MONI2

SDRWC     STA  MONCMD
          LDD  MONAD
          STD  MONAD2          SD.AD
          JSR  HNINP
          PSHS A
          LDD  MONAD
          STD  MONAD3          MEM.AD
          PULS A
          CMPA #$8D
          BEQ  SDRWEX           R/W ONE
          JSR  HNINP
          LDD  MONAD
          LDB  MONAD+1		LOOP COUNT
*
SDRWCLP   PSHS B
          BSR  SDRWEX
          LDD  MONAD2
          ADDD #1
          STD  MONAD2
          LDD  MONAD3
          ADDD #256
          STD  MONAD3
          PULS B
          DECB
          BNE  SDRWCLP
          RTS
          
SDRWEX    LDD  MONAD2		TRACK.SECTER
          LDX  MONAD3		R/W.BUF.ADR
          TST  MONCMD           0=READ / 1=WRITE
          BNE  SDRWEX2
          JSR  SDREAD
          RTS
SDRWEX2   JSR  SDWRITE		SDWRITE(256B)
          RTS

FILLDT    LDD  MONAD
          STD  MONAD2		START
          JSR  HNINP
          LDD  MONAD
          STD  MONAD3		END
          JSR  HNINP
          LDA  MONAD+1		FILL.DT
          LDX  MONAD2
FILDT2    STA  0,X
          CMPX MONAD3
          BNE  FILDT3
          RTS
FILDT3    LEAX 1,X
          BRA  FILDT2


DUMP      TST  HNINPWK
          BEQ  DUMPEX
          LDX  MONAD
          STX  MONAD2
DUMPEX    LDB  #8
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
          RTS

H1IN      JSR  CONSIN
          CMPA #$3A
          BGE  H1IN2
          SUBA #$30
          RTS
H1IN2     CMPA #$47
          BGE  H1IN3
          SUBA #$37
          RTS
H1IN3     SUBA #$57
          RTS
HDTIN     BSR  H1IN
          ASLA
          ASLA
          ASLA
          ASLA
          STA  HLOADWK
          BSR  H1IN
          ADDA HLOADWK
          RTS
HLOAD     LDX  #LOADMSG
          JSR  STROUT
HLOAD1    LDA  #$25           DISPLAY '%'
          JSR  PUTCHR
          JSR  CONSIN
          CMPA #$3A           ? :
          BNE  HLOAD
          BSR  HDTIN          A = DL
          STA  HLOADDL
          BSR  HDTIN
          STA  HLOADAD        ADDRESS
          BSR  HDTIN
          STA  HLOADAD+1
          BSR  HDTIN
          BEQ  HLOAD2         00 = DATA.LINE
          JSR  CROUT
          LDD  HLOADAD
          JSR  H4OUT
          LDA  #$0D
          RTS
HLOAD2    LDX  HLOADAD
          LDB  HLOADDL
HLOAD3    BSR  HDTIN
          STA  ,X+
          DECB
          BNE  HLOAD3
          BSR  HDTIN          SUM(DUMY.READ)
          jSR  CONSIN         CR (DUMY.READ)
          BRA  HLOAD1

H1INP     JSR  CONSINWE
          CMPA #$0D
          BEQ  H1INPER
          SUBA #$30
          CMPA #$0A
          BLT  H1INPE
          SUBA #$7
H1INPE    RTS
H1INPER   ORA  #$80
          RTS
H2INP     BSR  H1INP
          LSLA
          LSLA
          LSLA
          LSLA
          PSHS A
          BSR  H1INP
          ADDA ,S+
          RTS
H4INP     BSR  H2INP
          PSHS A
          BSR  H2INP
          PSHS A
          PULS B
          PULS A
          RTS
HNINP     LDD  #0
          STD  MONAD
          CLR  HNINPWK
HNINP2    
          BSR  H1INP
          BITA #$80
          BNE  HNINPE
          INC  HNINPWK
          PSHS A
          LDD  MONAD
          LSLB
          ROLA
          LSLB
          ROLA
          LSLB
          ROLA
          LSLB
          ROLA
          STD  MONAD		MONAD <- SIFT4
          PULS A
          ORA  MONAD+1
          STA  MONAD+1
          BRA  HNINP2
HNINPE    CMPA #$8D
          BEQ  HNINPE2
          TST  HNINPWK
          BEQ  HNINP2
HNINPE2   RTS

H1OUT     PSHS A
          ADDA #$30
          CMPA #$39
          BLE  H1OUT2
          ADDA #$07
H1OUT2    BSR  PUTCHR
          PULS A
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

* CONSOLE IN
CONSINWE  BSR  CONSIN		WITH ECHO
          BRA  PUTCHR
CONSIN    BSR  KEYIN          GET A CHARACTER FROM CONSOLE IN
          BEQ  CONSIN         LOOP IF NO KEY DOWN
          RTS

KEYIN     LDA  USTAT
          BITA #1
          BEQ  NOCHAR
          LDA  RECEV
          ANDA #$7F
          CMPA #$60
          BLT  KEYINR
          SUBA #$20
KEYINR    RTS
NOCHAR    CLRA
          RTS

STROUT    LDA  0,X
          BEQ  STROUTE
          BSR  PUTCHR
          LEAX 1,X
          BRA  STROUT
STROUTE   RTS

SPOUT     LDA  #$20
          BRA  PUTCHR
CROUT     LDA  #$0D
          BRA  PUTCHR

* CONSOLE OUT
PUTCHR    BSR  WAITACIA
          STA  TRANS
          RTS

WAITACIA  PSHS A
WRWAIT    LDA  USTAT
          BITA #2
          BEQ  WRWAIT
          PULS A
          RTS

TESTMSG   LDA  #$41           
          BSR  PUTCHR
          LDA  #$42           
          BSR  PUTCHR
          LDA  #$43           
          BSR  PUTCHR
          RTS

INITMSG   FCB  $0D
          FCC  "MON6809"
          FCB  CR,0
LOADMSG   FCC  "LOAD.HEX"
          FCB  CR,0

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


*  SET VECTER
          ORG  ROMBASE+$1FFE
          FDB  RSTART           RESET START

