/* console.c -- debug console 
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
#include <signal.h>
#include <unistd.h>
#include <ctype.h>

#include "config.h"
#include "emu6809.h"
#include "console.h"

#include <curses.h>
#include <locale.h>
#include <sys/stat.h>

int m6809_swi_call(void);
void getkeys(char *input);

extern int stepcnt;
extern tt_u8 *brkbuf, brksts;
extern char *drv0dsk, *drv1dsk, *drv2dsk,*drv3dsk;

char drv0fnb[256],drv1fnb[256],drv2fnb[256],drv3fnb[256];
long cycles = 0;
int activate_console = 0;
int console_active = 0;
tt_u8 console_mode = 0;

tt_u8 dbgtest;
int pctrace=0;
tt_u8 bkeyin=0, bkeyset = 0, ddskmsg=0;
int regwork,regdata,regdflg;
int argcsv;
char **argvsv;
tt_u16 wstartadr;
tt_u16 prepc;

static void sigbrkhandler(int sigtype){
  if (!console_active)
    activate_console = 1;
}

static void setup_brkhandler(void){
  signal(SIGINT, sigbrkhandler);
}

void set_rawmode(){
    setlocale(LC_ALL, "");
    WINDOW *w; w = initscr();
    if (w == NULL) fprintf(stderr, "Error initializing curses library.\n");
    raw();              /* Terminal in raw mode, no buffering */
	cbreak();
    noecho();           /* Disable echoing */
    nonl();             /* Disable newline/return mapping */
    keypad(w, FALSE);   /* FALSE: CSI codes, TRUE: curses codes for keys */
}

void console_init(void)
{
  set_rawmode();
  echochar(0x0d);
  printf("sim6809 v0.1 - 6809 simulator\nCopyright (c) 1998 by Jerome Thoen\n\n");
}

int execute(){
  int n,m=0;
  int r = 0;
  int step = activate_console;

  prepc = rpc;
  do {
    activate_console = step;
    while ((n = m6809_execute(pctrace)) > 0 && !activate_console && brkbuf[rpc]==0 && bkeyin==0) {
	  cycles += n; prepc = rpc;
	  if(bkeyset){
		  m++;
		  if(m==1000000) {
		  	m=0; printf("."); 	// print ....
			timeout(0);	int kin = getch(); if(kin != -1) {activate_console = r = 1;}
		  }
	  }
    }

    if (activate_console && n > 0) cycles += n;
    
    if (n == SYSTEM_CALL) {
	  r = activate_console = m6809_swi_call();
	} else 
	  if (n < 0) {
        printf("m6809 run time error, return code %d\n", n);
        activate_console = r = 1; step = 0;
      }
	  
	  if((brkbuf[rpc] & 0x0f)!=0 || bkeyin!=0) {
	    if((brkbuf[rpc] & 0x0f)==2){
		  printf(" ! Trace "); dis6809(rpc, stdout);
		} else {
		  if(bkeyin!=0) rpc = prepc;	// Retrai
		  //if(bkeyin==0x04){				// CTRL + D ... Get File
		  //  set_battxt();
		  //  bkeyin=0;
		  //} else 
		  if((brkbuf[rpc] & 0x0f)!=0 || bkeyin==0x03){
	        printf("\n!B "); dis6809(rpc, stdout);
	  	    activate_console = r = 1; // stop run;
		    bkeyin=0;
		  }
		  else bkeyin = 0;
		}
	  }
  } while (!activate_console);

  return r;
}

void ignore_ws(char **c){
  while (**c && isspace(**c))
    (*c)++;
}

tt_u16 readhex(char **c){
  tt_u16 val = 0;
  char nc;
  ignore_ws(c);
  nc = toupper(**c);
  if(nc=='P'){
    val = rpc; (*c)++;
  } else {
    while (isxdigit(nc = **c)){
      (*c)++; val *= 16;
      nc = toupper(nc);
      if (isdigit(nc)) { val += nc - '0'; } 
	  else             { val += nc - 'A' + 10; }
    }
  }
  return val;
}

int readint(char **c){
  int val = 0;
  char nc;
  ignore_ws(c);
  while (isdigit(nc = **c)){
    (*c)++; val *= 10; val += nc - '0';
  }
  return val;
}

char *readstr(char **c){
  static char buffer[256];
  int i = 0;
  ignore_ws(c);
  while (!isspace(**c) && **c && i < 255)
    buffer[i++] = *(*c)++;
  buffer[i] = '\0';
  return buffer;
}

int more_params(char **c){
  ignore_ws(c);
  return (**c) != 0;
}

char next_char(char **c){
  ignore_ws(c);
  return *(*c)++;
}

void get_fddname(char **c){
  int i;
  char *strptr = (*c);
	  if(more_params(&strptr)){
	    while(more_params(&strptr)){
	      i = readint(&strptr);
		  if(more_params(&strptr) && i<4){
		    switch(i){
		      case 0 : strcpy( drv0fnb, readstr(&strptr)); drv0dsk = drv0fnb; break;
		      case 1 : strcpy( drv1fnb, readstr(&strptr)); drv1dsk = drv1fnb; break;
		      case 2 : strcpy( drv2fnb, readstr(&strptr)); drv2dsk = drv2fnb; break;
		      case 3 : strcpy( drv3fnb, readstr(&strptr)); drv3dsk = drv3fnb; break;
			}
		  }
	    }
	  } 
	  printf("DSK0: %s\nDSK1: %s\nDSK2: %s\nDSK3: %s\n", drv0dsk, drv1dsk, drv2dsk, drv3dsk);
}

void console_command()
{
  static char input[80], copy[80];
  char *strptr, ch;
  tt_u16 memadr, start, end;
  tt_u16 bparam, badrin;
  long n;
  int i, r;
  int regon = 0;

  for(;;) {
    activate_console = 0; console_active = 1;
    printf("> "); fflush(stdout);
	//if(fgets(input, 80, stdin) == 0) return;
	
	getkeys(input);
	if (strlen(input) == 1)
      strptr = copy;
    else
      strptr = strcpy(copy, input);
    
	console_mode = tolower(next_char(&strptr));
    switch (console_mode) {
    case 'b' :
      if (more_params(&strptr)) bparam = readhex(&strptr);
	  else                      bparam = 0;
	  	  if(bparam==0x0c) {
	    for(i=0;i<0x10000; i++) brkbuf[i] = 0;  // opc bpoint clear all
	  }  else if(bparam<=3){
		while(more_params(&strptr)){ // set bpoint
	      badrin = readhex(&strptr);
	      brkbuf[badrin] = bparam;
		}
		bparam = 0;
	  } else if(bparam>=0x80){
	    if((bparam&0x40)!=0) pctrace = 1; else pctrace = 0;
	    if((bparam&0x20)!=0) bkeyset = 1; else bkeyset = 0;
	    if((bparam&0x10)!=0) ddskmsg = 1; else ddskmsg = 0;
	    dbgtest = bparam & 0x0f;
		printf("pctrace = %d\n", pctrace);
		printf("bkeyset = %d\n", bkeyset);
		printf("ddskmsg = %d\n", ddskmsg);
		printf("dbgtest = %X\n", dbgtest);
		bparam = 0;
	  }
	  
	  if(bparam==0)
 	    for(i=0;i<0x10000; i++)
	      if(brkbuf[i]!=0) printf("B %2X %04hX\n", brkbuf[i], i); // bpoint disp
      break;
    case 'c' :
	  start = 0; end = 0xffff; i = 0;
	  if (more_params(&strptr)) {
	    start = readhex(&strptr);
		if (more_params(&strptr)) {
		  end = readhex(&strptr);
		  if (more_params(&strptr)) i = readhex(&strptr);
	  } }
      for (n = start; n <= end; n++)
	    set_memb((tt_u16)n, i);
      printf("Memory cleared: %x %x %x\n", start, end, i);
      break;
    case 'd' :
      if (more_params(&strptr)) {
	    if(*strptr==',') start = memadr; 
		else             start = readhex(&strptr);
	    if (more_params(&strptr))
		  if(*strptr==',') end = start + 0x1f;				// d ssss,
		  else             end = readhex(&strptr);			// d ssss eeee
	    else               end = start;						// d ssss
      } else                       start = end = memadr;	// d
      for(n = start; n <= end && n < 0x10000; ){
	    printf("   "); n += dis6809((tt_u16)n, stdout);
	  }
      memadr = (tt_u16)n;
      break;

    case 'f' :
      get_fddname(&strptr);
	  break;
/*
      if (more_params(&strptr)) {
		console_active = 0;
	    //execute_addr(readhex(&strptr));
		if(*strptr==',')      badrin = rpc + 3;
		else if(*strptr=='.') badrin = rpc + 2;
		     else             badrin = readhex(&strptr);
		brkbuf[badrin] = brkbuf[badrin] | 4;
	    execute();
		brkbuf[badrin] = brkbuf[badrin] & 0xfb;
		
		if (regon) {
	      m6809_dumpregs();
	      printf(" N ");
	      dis6809(rpc, stdout);
	    }
	    memadr = rpc;
      } else
	  printf("Syntax Error. Type 'h' to show help.\n");
      break;
*/
    case 'g' :
      if (more_params(&strptr))	{
	    if(tolower(*strptr)=='r') rpc = get_memw(0xfffe);
	    else                      rpc = readhex(&strptr);
      }
	  console_active = 0;
      execute();
      if (regon) {
	    m6809_dumpregs();
	    printf(" N ");
	    dis6809(rpc, stdout);
      }
      memadr = rpc;
      break;

    case 'h' : case '?' :
      printf("     HELP for the 6809 simulator debugger\n\n");
      printf("   c               : clear memory\n");
      printf("   d [start] [end] : disassemble memory from <start> to <end>\n");
      printf("   f adr           : step forward until PC = <adr>\n");
      printf("   g [adr]         : start execution at current address or <adr>\n");
      printf("   h, ?            : show this help page\n");
      printf("   l file          : load Intel Hex binary <file>\n");
      printf("   m [start] [end] : dump memory from <start> to <end>\n");
      printf("   m [start]-      : dump memory from <start> to <start>+0x100\n");
      printf("   m [start]       : modify memory [mmmm: dt] or [mmmm: dt dt ...]\n");
	  printf("   n [num]         : next [num] instruction(s)\n");
      printf("   p adr           : set PC to <adr>\n");
      printf("   q               : quit the emulator\n");
      printf("   r               : dump CPU registers\n");
      printf("   r xx            : Disp Register For Next(xx=HEX A.B.X.Y.U.S.DP.CC)\n");
      printf("   r xx yy         : Set Register(xx) to yy\n");
	  #ifdef PC_HISTORY
      printf("   s               : show PC history\n");
      printf("   t               : flush PC history\n");
#endif
      printf("   u               : toggle dump registers\n");
      printf("   y [0]           : show number of 6809 cycles [or set it to 0]\n");
      break;

    case 'l' :
      if (more_params(&strptr))	load_intelhex(readstr(&strptr));
      else                      printf("Syntax Error. Type 'h' to show help.\n");
      break;
    case 'm' :
	  activate_console = 1;
      if (more_params(&strptr)) {
	    if(*strptr==',') { n = memadr; strptr++;}
	    else             n = readhex(&strptr);
	    if(*strptr==',') { end = n + 0xff; strptr++; }
	    else if(*strptr=='.') end = (n & 0xfff0) + 0x1f;
		else
	      if (more_params(&strptr)) end = readhex(&strptr);
	      else { 
		    for(;;){	// Memory Change
		      printf("%04hX: %02hX ", (unsigned int)n, get_memb(n));
              getkeys(input);
			  strptr = strcpy(copy, input);
			  if(*strptr==' '){
			    n++;
			  } else {
			    if (!more_params(&strptr)) break;
			    for(;;){
			      if (!more_params(&strptr)) break;
                  tt_u8 kd = readhex(&strptr);
			      set_memb(n++, kd);
			    }
			  }
			}
			end = n;
		  }
      } else 
	    n = end = memadr;
	  // Memory Dump
	  if(n < (long)end) printf("Addr: 00-01-02-03-04-05-06-07-08-09-0A-0B-0C-0D-0E-0F 0123456789ABCDEF\n");
      while (n < (long)end) { // Memory Dump
	    n = n & 0xfff0;
	    printf("%04hX: ", (unsigned int)n);
	    for (i = 0; i < 16; i++) printf("%02X ", get_memb(n+i));
	    for (i = 0; i < 16; i++) {
	      tt_u8 v = get_memb(n++);
	      if (v >= 0x20 && v <= 0x7e) putchar(v);
	      else                        putchar('.');
	    }
	    putchar('\n');
      }
      memadr = n;
      break;
    case 'n' :
	  i = 0;
	  if     (*strptr==',') { badrin = rpc + stepcnt; i = 1; }
	  //else if(*strptr=='.') { badrin = rpc + 2; i = 1; }
	  else if(*strptr=='=') { strptr++; badrin = readhex(&strptr); i = 1;}
	  if(i){
	    // Step.over Mode
		brkbuf[badrin] = brkbuf[badrin] | 4;
	    execute();
		brkbuf[badrin] = brkbuf[badrin] & 0xfb;
      } else {
	    // Trace.Mode
        if (more_params(&strptr)) i = readint(&strptr);
        else                      i = 1;
          while (i-- > 0) {
	        activate_console = 1;
	        if (!execute()) {
	          printf(" N ");
	          memadr = rpc + dis6809(rpc, stdout);
	          if (regon) m6809_dumpregs();
	        } else
	          break;
          }
	  }
	  memadr = rpc;
      break;
    case 'p' :
      if(more_params(&strptr)) rpc = readhex(&strptr);
      else printf("Syntax Error. Type 'h' to show help.\n");
      break;
    case 'q' :
      return;
    case 'r' :
      if (more_params(&strptr)) {
	    ch = *strptr++;
		if (more_params(&strptr)){
		  regdata = readhex(&strptr);
		  switch(ch) {
		    case 'a': ra = regdata; break;
		    case 'b': rb = regdata; break;
		    case 'x': rx = regdata; break;
		    case 'y': ry = regdata; break;
		    case 'u': ru = regdata; break;
		    case 's': rs = regdata; break;
		    case 'd': rdp = regdata; break;
		    case 'c': setcc(regdata); break;
			case 'p': rpc = regdata; break;
		    default : regdflg = regdata & 0xff; printf("Reg.Disp = %2x\n", regdflg); break;
		  }
		}
	  } 
	  //else 
        dis6809(rpc, stdout);; //m6809_dumpregs();
      break;
#ifdef PC_HISTORY
    case 's' :
      r = pchistidx - pchistnbr;
      if (r < 0)
	r += PC_HISTORY_SIZE;
      for (i = 1; i <= pchistnbr; i++) {
	dis6809(pchist[r++], stdout);
	if (r == PC_HISTORY_SIZE)
	  r = 0;
      }
      break;
    case 't' :
      pchistnbr = pchistidx = 0;
      break;
#endif
    case 'u' :
      regon ^= 1;
      printf("Dump registers %s\n", regon ? "on" : "off");
      break;
    case 'w' :
      if(more_params(&strptr)) 	wstartadr = readhex(&strptr);
      else                      { rpc = wstartadr; execute();}
	  memadr = rpc;
	  break;
    case 'y' :
      if (more_params(&strptr))
	if(readint(&strptr) == 0) {
	  cycles = 0;
	  printf("Cycle counter initialized\n");
	} else
	  printf("Syntax Error. Type 'h' to show help.\n");
      else {
	double sec = (double)cycles / 1000000.0;

	printf("Cycle counter: %ld\nEstimated time at 1 Mhz : %g seconds\n", cycles, sec);
      }
      break;
    default :
      printf("Undefined command. Type 'h' to show help.\n");
      break;
    }
  }
}

void parse_cmdline(int argc, char **argv)
{
  if (--argc == 0)
    return;
  if (!strcmp(argv[1], "-h")) {
    printf("%s: [file [...]]\n", argv[0]);
    exit(0);
  }
  //while (argc-- > 0)
  //  load_intelhex(*++argv);
  argcsv = argc; argvsv = argv;
}

int main(int argc, char **argv)
{
  if (!memory_init())
    return 1;
  parse_cmdline(argc, argv);
  console_init();
  m6809_init();
  setup_brkhandler();
  console_command();

  return 0;
}
