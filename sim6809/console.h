/* console.h
   Copyright (C) 1998 Jerome Thoen

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.  */

#define ACIA0CTR 0xe004
#define ACIA0DAT 0xe005

#define FD_Drvreg 0xe014
#define FD_Comreg 0xe018
#define FD_Trkreg 0xe019
#define FD_Secreg 0xe01a
#define FD_Datreg 0xe01b

#define MPT       0xe042	// & e0e3  Timer 6840?
#define MPLPIA    0xe070	//         Printer 6821?

extern int activate_console;
extern int debugio;

/*
Command				>80	>40	>20	>10	>08	>04	>02	>01
Restore				0	0	0	0	h	V	r1	r0
Seek				0	0	0	1	h	V	r1	r0
Step				0	0	1	T	h	V	r1	r0
Step-in				0	1	0	T	h	V	r1	r0
Step-out			0	1	1	T	h	V	r1	r0
Read sector			1	0	0	m	S	E	C/0	0
Write sector		1	0	1	m	S	E  C/a1	a0
Read ID				1	1	0	0	0	E'	0	0
Read track			1	1	1	0	0	E'	0	s*
Write track			1	1	1	1	0	E'	0	0
Force interrupt		1	1	0	1	I3	I2	I1	I0

r0,r1: stepping motor rate (see below)
V: verify track number flag. 1=verify, 0=don't.
h: head load flag. 0=unload head at beginning, 1=load head at beginning.
T: track update flag. 1=update track register, 0=don't.

a0: data mark flag. For FD179x: 0=data mark (>FB), 1=deleted data mark (>F8). For FD1771: combined with C to select one in 4 possible data marks: 00 = >FB, 01 = FA, 10 = >F9, 11 = >F8.
E: delay flag: 0=no delay, 1=15 msec delay before sampling the HLT pin (10 msec for FD1771).
E': same as E, but always 1 with FD1771.
C/a1: For FD1795/97: compare side number flag. 0=disable, 1=enable: set value of SSO pin (for all read/write commands). For the FD1771: always 0 for read command, combines with a0 for write commands.
S: For FD 1791/2/3: expected side, to be compared to side number on disk if C=1. For FD1771 and FD1795/97: changes the meaning of the sector size code.
m: multiple record flag. 0=read/write one sector. 1=keep reading/writing sectors on that track until Force interrupt is issued.
s*: For FD1771 only. Synchronize to address marks if 0, ignore address marks if 1. Always enabled with the FD179x.

I3: issue an interrupt now. This bit can only be reset with another "Force interrupt" command.
I2: issue an interrupt at the next index pulse.
I1: issue an interrupt at the next ready to not-ready transition of the READY pin.
I0: issue an interrupt at the next not-ready to ready transition of the READY pin.
(If I0-I3 are 0: don't issue any interrupt, but still abort the current command).


Status register

Command			>80			>40				>20			>10				>08			>04		>02			>01
All steppings +
Force interrupt	Not ready	Write protect	Head loaded	Seek error		(CRC error)	Track 0	Index pulse	Busy
Read ID			Not ready	0				0			Rec not found	CRC error	Lost data	DRQ pin	Busy
Read sector		Not ready	0 (Mark type)	Mark type	Rec not found	CRC error	Lost data	DRQ pin	Busy
Read track		Not ready	0				0			0				0			Lost data	DRQ pin	Busy
Write sector	Not ready	Write protect	Write fault	Rec not found	CRC error	Lost data	DRQ pin	Busy
Write track		Not ready	Write protect	Write fault	0				0			Lost data	DRQ pin	Busy
*/