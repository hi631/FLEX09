                NAM     DRIVERS 
                PAG

* ---------------------------------------------------------------------------
* File Name   : DRIVERS.ASM
* Format      : XASM09.EXE
*
* Processor:       6809 []
* Target assebler: Public domain 6809 assembler v2.01 (OS9 support)
*
*       This is a dissassembly of the actual code running in the 
*       6809 box with the SBUG17/OS9 ROM set. This is from the
*       PL9-MACE boot diskette.
*

SCRATCH3        equ     $CC30
CPUFLAG         equ     $CC33
SPLFLG          equ     $CC34           spooling active flag
WARMS           equ     $CD03

MONTH           equ     $CC0E
DAY             equ     $CC0F
YEAR            equ     $CC10

HOUR            equ     $D370               
MINUTE          equ     $D371
SECOND          equ     $D372
TICK            equ     $D373

SWIVEC          equ     $DFC2
IRQVEC          equ     $DFC8

ACIADD          equ     $DFE0

ACIAS           equ     $E004
MPT             equ     $E042
MPLPIA          equ     $E070

CON_BASE        equ		$F200
DSK_BASE        equ		$F210
INCH            equ     CON_BASE+$04
INCHE           equ     CON_BASE+$06
INCHEK          equ     CON_BASE+$08
OUTCH           equ     CON_BASE+$0A

*
* CONSOLE I/O DRIVER VECTOR TABLE
*
                ORG     $D3E1       * TABLE STARTS AT $D3E1

LD3E1           FDB     ADDDEV      * add an IRQ handler to table
                FDB     DELDEV      * delete an IRQ handler from table

                FDB     INCHNE      * ($E86F) INPUT CHARACTER W/O ECHO
                FDB     IHNDLR      * ($E873) IRQ INTERRUPT HANDLER
                FDB     SWIVEC      * ($DFC2) SWI3 VECTOR LOCATION
                FDB     IRQVEC      * ($DFC8) IRQ VECTOR LOCATION
                FDB     TMOFF       * ($E8D6) TIMER OFF ROUTINE
                FDB     TMON        * ($E8D0) TIMER ON ROUTINE
                FDB     TMINT       * ($E8B4) TIMER INITIALIZATION
                FDB     MONITR      * ($E844) MONITOR ENTRY ADDRESS
                FDB     TINIT       * ($E850) TERMINAL INITIALIZATION
                FDB     STAT        * ($E867) CHECK TERMINAL STATUS
                FDB     VOUTCH      * ($E863) OUTPUT CHARACTER
                FDB     VINCH       * ($E85A) INPUT CHARACTER W/ ECHO

*
* DISK DRIVER ROUTINE JUMP TABLE
*
                ORG     $DE00

DREAD           JMP     >DSK_BASE+0  * DE00 7E E955   READ      Read a single sector
DWRITE          JMP     >DSK_BASE+3  * DE03 7E E9B9   WRITE     Write a single sector
DVERFY          JMP     >DSK_BASE+6  * DE06 7E EA21   VERIFY    Verify last sector written
DRESTOR         JMP     >DSK_BASE+9  * DE09 7E EAE8   RESTORE   Restore head to track #0
DDRIVE          JMP     >DSK_BASE+12 * DE0C 7E EB00   DRIVE     Select the specified drive
DCHECK          JMP     >DSK_BASE+15 * DE0F 7E EB42   CHKRDY    Check for drive ready
DQUICK          JMP     >DSK_BASE+18 * DE12 7E EB82   QUICK     Quick check for drive ready
DINIT           JMP     >DSK_BASE+21 * DE15 7E EAD2   INIT      Driver initialize (cold start)
DWARM           JMP     >DSK_BASE+24 * DE18 7E EADD   WARM      Driver initialize (warm start)
DSEEK           JMP     >DSK_BASE+27 * DE1B 7E EA36   SEEK      Seek to specified track

DRVTBL          FCB     $00,$00,$00,$00
                FCB     $00,$00,$00,$00
                FCB     $00,$00,$00,$00

                org $F000

* ---------------------------------------------------------------------------
*       Printer port initialization

OPNPRT          ldx     <PPORT,pc
                lda     #$3A
                sta     1,x
                lda     #$FF
                sta     ,x
                lda     #$3E
                sta     1,x
                rts

* ---------------------------------------------------------------------------
*       Close the printer device (issue a <CR>)

CLSPRT          lda     #$D

* ---------------------------------------------------------------------------
*       Output a character to the printer

OUTPRT          bsr     CHKPRT
                bpl     OUTPRT

                pshs    x
                clr     <IRQBM,pc
                ldx     <PPORT,pc
                sta     ,x
                lda     #$36
                sta     1,x
                lda     #$3E
                sta     1,x
                puls    pc,x

* ---------------------------------------------------------------------------
*       check for printer ready

CHKPRT          pshs    x
                tst     <IRQBM,pc
                bmi     CHKDONE

                ldx     <PPORT,pc
                tst     1,x
                bpl     CHKDONE

                tst     ,x
                com     <IRQBM,pc

CHKDONE         puls    pc,x

* ---------------------------------------------------------------------------
PPORT           fdb     MPLPIA              * address of device
                fdb     0                   * IRQ handler address
IRQBM           fcb     0                   * bit mask for IRQ flag
* ---------------------------------------------------------------------------
*       Monitor entry routine
MONITR          lda     #$A
                bsr     VOUTCH              * output character
                lda     #$D
                bsr     VOUTCH              * output character
                swi                         * enter monitor
                jmp     WARMS               * re-enter FLEX gracefully
* ---------------------------------------------------------------------------
*       Terminal init routine
TINIT           pshs    a
                lda     #$11
                fcb		$12,$12,$12,$12		* sta     [ACIADD]
                puls    pc,a
* ---------------------------------------------------------------------------
*       Terminal input routine
VINCH           tst     >TAPPTR             * allow redirection of input from terminal
                beq     TREDIR              * redirection not required
                jsr     [TAPPTR]            * redirect to alternate routine
* ---------------------------------------------------------------------------
*       Terminal output routine
VOUTCH          jmp     [OUTCH]
* ---------------------------------------------------------------------------
*       Terminal status check routine
STAT            jmp     [INCHEK]
* ---------------------------------------------------------------------------
*       Monitor terminal input character with echo
TREDIR          jmp     [INCHE]
* ---------------------------------------------------------------------------
*       Monitor terminal input character without echo
INCHNE          jmp     [INCH]
* ---------------------------------------------------------------------------
* Interupt handler

IHNDLR          leau    <IRQLL-4,pc         get address of IRQ handler linked list
CHKNXT          ldu     4,u                 get a link
                beq     IHDONE              end of list

                lda     [,u]                get status from device
                bita    6,u                 did it interrupt?
                beq     CHKNXT              no - check next

                ldy     ,u                  yes - get address of device in Y
                jmp     [2,u]               go to device ISR

IHDONE          rti                         return from interrupt

* ---------------------------------------------------------------------------
*       add a device to IRQ handler table

ADDDEV          pshs    x,y,u               
                bsr     SRCHLST             find link in chain
                beq     DEVARE              already exists - exit
                stu     4,x                 set link pointer in new ctl blk
                stx     4,y                 link this one into prev blk
DEVARE          puls    pc,u,y,x            

* ---------------------------------------------------------------------------
*       delete a device from IRQ handler table

DELDEV          pshs    x,y,u
                bsr     SRCHLST             find link in chain
                bne     NODEV               not found - exit
                ldx     4,x                 get link from ctl blk to delete
                stx     4,u                 set in prev block
NODEV           puls    pc,u,y,x            

* ---------------------------------------------------------------------------
*       search a linked list
*
*               entry: X = address of ISR control block
*               exit:  Y = address of link pointer
*                     CC = Z bit set if already linked
*
*               format of ISR control block:
*
*                       offset  description
*                         0     address of I/O device
*                         2     address of ISR
*                         4     link to next ISR control block
*                         6     bit mask for determining IRQ

SRCHLST         leau    <IRQLL-4,pc
SRCHLP          leay    ,u
                cmpx    4,u                 X = link?
                beq     FNDENT              yes - return pointer in U

                ldu     4,u                 no - get link in U
                bne     SRCHLP              not end of chain - loop
                andcc   #$FB                clear Z flag in CC

FNDENT          rts                         return - not found

* --------------------------------------------------------------------

IRQLL           fdb     0                   pointer to first entry in the table
                fcb     1                   

TAPPTR          fdb     0                   no terminal input redirection

* --------------------------------------------------------------------
*       Timer routines for MPT
*
*       timer initialize - install the handler into the chain

TMINT           ldx     #MPT                point to hardware
                lda     #$FF                set up the port direction
                sta     ,x
                lda     #$3C
                sta     1,x
                lda     #$8F                this turns it off so it does
                sta     ,x                  not fire before the handler
                lda     ,x                  get's installed
                lda     #$3D
                sta     1,x

*               point X at address of timer handler control block

                ldx     #TIMER
                jmp     [LD3E1]             Add it to the linked list of handlers

* --------------------------------------------------------------------
*       timer on

TMON            lda     #4                  10 millisecond ticks
                sta     MPT                 enable the timer
                rts

* --------------------------------------------------------------------
*       timer off

TMOFF           lda     #$8F                disable the timer
                sta     MPT
                rts
* --------------------------------------------------------------------
*
*   Interrupt handler for the MP-T card.
    
IHND            lda     MPT                 kill IRQ flag in MPT
                inc     TICK                bump tick counter
                lda     TICK
                cmpa    #100                100 ticks?
                bne     NOUP                no - skip to spooler

                clr     TICK                yes - reset tick counter
                inc     SECOND              - increment second counter
                lda     SECOND              see if overflow
                cmpa    #60
                bne     NOUP                no - don't update minutes

                clr     SECOND              yes - reset seconds
                inc     MINUTE              increment minute
                lda     MINUTE              
                cmpa    #60                 see if overflow
                bne     NOUP                no - don't update hour

                clr     MINUTE              yes - reset minute
                inc     HOUR                increment hours
                lda     HOUR               
                cmpa    #24                 overflow?
                bne     NOUP                no - don't update day

                clr     HOUR                yes - reset hours
                inc     DAY                 increment system day
                lda     DAY                 get the day
                leax    MONTHDAYS,pc        point to days per month table
                ldb     MONTH               get month in b for offset
                decb                        make zero based
                leax    b,x                 set X to point to correct entry
                inca                        
                cmpa    ,x
                bne     NOUP                not time to change month yet

                lda     #1                  reset the day to the first
                sta     DAY
                inc     MONTH               bump the month
                lda     MONTH               get the month value
                cmpa    #13                 see if overflow
                bne     NOUP                no

                lda     #1                  set back to January
                sta     MONTH               
                inc     YEAR                and bump to next year

NOUP            jmp     $C700               go to spooler code

MONTHDAYS       fcb     31                  Jan
                fcb     28                  Feb
                fcb     31                  Mar
                fcb     30                  Apr
                fcb     31                  May
                fcb     30                  Jun
                fcb     31                  Jul
                fcb     31                  Aug
                fcb     30                  Sep
                fcb     31                  Oct
                fcb     30                  Nov
                fcb     31                  Dec

TIMER           fdb     MPT+1               * where we can find device status byte
                fdb     IHND                * pointer to Interrupt handler
                fdb     0                   * pointer to next device in chain
                fcb     $80                 * mask for testing Interrupt occured

                END     $C850
