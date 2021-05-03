/* memory.c -- Memory emulation
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


#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "config.h"
#include "emu6809.h"
#include "console.h"

extern tt_u8 brkmemon(tt_u8 mmode, tt_u16 adr, tt_u8 val);	// opton memory opration
tt_u8 *ramdata;		// 64KB of ram
tt_u8 *brkbuf;		// 64KB of OP.Break.Table
tt_u8 *brkmem;		// 64KB of MEM.Break.Table
tt_u8 iommap[128] = {	// I/O Break Map
0x00,0x00,0x00,0x00,0xc0,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0xc0,0x00,0x00,0x00,0xc0,0xc0,0xc0,0xc0,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0xc0,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xc0,0xc0,0xc0,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 };
int memory_init(void)
{
  ramdata = (tt_u8 *)mmalloc(0x10000);
  brkbuf  = (tt_u8 *)mmalloc(0x10000);
  brkmem  = (tt_u8 *)mmalloc(0x10000);
  memset( ramdata, 0xff, 0x10000);
  memset( brkbuf , 0x00, 0x10000);
  memset( brkmem , 0x00, 0x10000);
  
  memcpy(&brkmem[0xe000], &iommap[0], 128);	// Set I/O Device addr
  brkmem[0xc400] = 0x80; 					// Set MEMEND
  
  return 1;
}

tt_u8 get_memb(tt_u16 adr)
{
  if((brkmem[adr] & 0x80)!=0) return brkmemon(0x80, adr, ramdata[adr]);
  else                        return ramdata[adr];
}

tt_u16 get_memw(tt_u16 adr)
{
  return (tt_u16)get_memb(adr) << 8 | (tt_u16)get_memb(adr + 1);
}

void set_memb(tt_u16 adr, tt_u8 val)
{
  if((brkmem[adr] & 0x40)!=0) brkmemon(0x40, adr, val);
  else                        ramdata[adr] = val;
}

void set_memw(tt_u16 adr, tt_u16 val)
{
  set_memb(adr, (tt_u8)(val >> 8));
  set_memb(adr + 1, (tt_u8)val);
}


