CON_BASE        equ		$F200
DSK_BASE        equ		$F210
		ORG		CON_BASE

		FDB		0
		FDB		0
		FDB		INCH 	; Terminal input character without echo
		FDB		INCHE	; Terminal input character with echo
		FDB		INCHEK	; Terminal status check routinestatus check routine
		FDB		OUTCH	; Terminal output routine

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
		pshs	b
		lda 	#3
		swi			// Reg.b <- Console.in
		tfr		b,a
		puls	b
		rts

INCHE
		pshs	b
		lda 	#3
		swi				// Reg.b <- Console.in
		pshs	b
		lda		#4
		swi				// Reg.b -> Console.out
		puls	b
		tfr		b,a
		puls	b
		rts

INCHEK
		pshs	b
		lda 	#5
		swi			// Reg.b <- Console.in(no.wait)
		tfr		b,a
		puls	b
		tsta
		rts

OUTCH
		pshs	d
		tfr		a,b		// Reg.a = output.data
		lda		#4
		swi				// Reg.b -> Console.out
		puls	d
		rts

**********************************************
* FDD R/W
**********************************************
S_READ   
		pshs	y
		tfr		d,y
		ldb		#0
		lda		#6
		swi
		puls	y
		rts
S_WRITE  
		pshs	y
		tfr		d,y
		ldb		#1
		lda		#6
		swi
		puls	y
		rts
S_VERIFY 
		pshs	y
		tfr		d,y
		ldb		#2
		lda		#6
		swi
		puls	y
		rts
S_RESTORE
		pshs	y
		tfr		d,y
		ldb		#3
		lda		#6
		swi
		puls	y
		rts
S_DRIVE  
		pshs	y
		tfr		d,y
		ldb		#4
		lda		#6
		swi
		puls	y
		rts
S_CHKRDY 
		pshs	y
		tfr		d,y
		ldb		#5
		lda		#6
		swi
		puls	y
		rts
S_QUICK  
		pshs	y
		tfr		d,y
		ldb		#6
		lda		#6
		swi
		puls	y
		rts
S_INIT   
		pshs	y
		tfr		d,y
		ldb		#7
		lda		#6
		swi
		puls	y
		rts
S_WARM   
		pshs	y
		tfr		d,y
		ldb		#8
		lda		#6
		swi
		puls	y
		rts
S_SEEKIT 
		pshs	y
		tfr		d,y
		ldb		#9
		lda		#6
		swi
		puls	y
		rts
