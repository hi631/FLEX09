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

int getch2bbf(int tmode);
void getkeys(char *input);
int check_outch(tt_u8 kdt);
void drive_ctr();
int check_ctrl(int kdt, int tend);
void get_fddname(char **c);

extern tt_u8 console_mode;
extern int argcsv;
extern char **argvsv;
extern tt_u8 bkeyin,ddskmsg;
extern char txtfnb[256];
extern tt_u8 dbgtest;
extern tt_u16 prepc;


char *drv0dsk = "..\\dsk\\FLEX9SYS.DSK";
char *drv1dsk = "..\\dsk\\FLEX9USR.DSK";
char *drv2dsk = "";
char *drv3dsk = "";

tt_u8 seldrv;
tt_u8 FDD_Drvreg, FDD_Comreg, FDD_Trkreg, FDD_Secreg, FDD_Datreg;
tt_u16 FDD_Dcount, FDD_Dmax;
char file_rwbuf[512];
tt_u8 ACIA0RD = 0;
tt_u8 ACIA0STS = 0x02;
tt_u8 ACIA0CHK = 0;
int keydtime = 0;
int pausectl;

char txtfnb[256];
tt_u8 *txtbuf;
char txtbufcmd = ' ';
int txtbufp = -1; 
int txtbufmx;
int txtbufocm = 0;
int batcp = -1;
char batbf[256];

int mode_check(){ 
  getch2bbf(0);
  if(console_mode=='d' || console_mode=='m') return 0; else return dbgtest; 
}

void dmsg(char *msg, int hd){ if(mode_check()) printf("[%s %x %x]", msg, rpc, hd);}

tt_u8 file_read(tt_u8 ra, tt_u8 rb){
 FILE *fp;
 int dadr;
 tt_u8 ans;
 char *drvfn;
 if((seldrv<4)){
   switch(seldrv){
     case 0 : drvfn = drv0dsk; break;
     case 1 : drvfn = drv1dsk; break;
     case 2 : drvfn = drv2dsk; break;
     case 3 : drvfn = drv3dsk; break;
   }
   if ((fp = fopen( drvfn, "rb")) == NULL) { printf("%s open.error", drvfn); ans = 0; }
   else {
//     if(rb!=0){
       dadr = (int)ra*36+rb-1;
	   FDD_Dmax = 256;
       fseek(fp, dadr*256, SEEK_SET); fread(&file_rwbuf[0],FDD_Dmax,1,fp);
//	 } else {
//	   FDD_Dmax = 512;	// Boot Secter Read Only
//       fseek(fp, 0, SEEK_SET); fread(&file_rwbuf[0],FDD_Dmax,1,fp);
//	 }
     fclose(fp); ans = 0x04; // Z=1 OK
   }
 } else ans = 0;
 return ans;
}
tt_u8 file_write(tt_u8 ra, tt_u8 rb){
 FILE *fp;
 int dadr;
 tt_u8 ans;
 char *drvfn;
 if((seldrv<4)){
   switch(seldrv){
     case 0 : drvfn = drv0dsk; break;
     case 1 : drvfn = drv1dsk; break;
     case 2 : drvfn = drv2dsk; break;
     case 3 : drvfn = drv3dsk; break;
   }
   dadr = (int)ra*36+rb-1;
   if ((fp = fopen( drvfn, "r+b")) == NULL) { printf("%s open.error", drvfn); ans = 0; }
   else {
     fseek(fp, dadr*256, SEEK_SET);
     fwrite(&file_rwbuf[0],256,1,fp);
     fclose(fp); ans = 0x04;
   }
 } else ans = 0;
 return ans;
}

int getch2bbf(int tmode){
    static int keyscnt = 0;
	int kdt;
	char *pp;
	if((batcp<0 && argcsv==0 && txtbufp==-1) || tmode==0){
		keyscnt++;
		if(txtbufocm!=0x18 || keyscnt>1000){
		timeout(tmode); 
		kdt = getch(); //printf("%x",kdt);
		kdt = check_ctrl(kdt,0);
		keyscnt = 0;
		}
	} else if(txtbufp!=-1){
	    kdt = txtbuf[txtbufp++]; //printf("(%x)",kdt);
		if(txtbuf[txtbufp]==0x0a) txtbufp++;
		//printf("[%d %d]", txtbufmx, txtbufp);
		if(txtbufp>=txtbufmx){ 
		  txtbufp = -1; free(txtbuf); txtbufcmd = ' '; }
	} else {
		if(batcp==-1){
			argcsv--; pp = *++argvsv;
			//printf("[%s]", pp);
			strcpy(batbf, pp); batcp=0;
		}
		kdt = batbf[batcp++];
		if(kdt==0) { kdt=0x0d; batcp=-1;}
	}
	return kdt;
}
unsigned char hcnvtbl[23] = { 0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,10,11,12,13,14,15};
void keyinchk(int wait){
  tt_u16 keyinwk;
  if((ACIA0STS & 1)==0 && ACIA0CHK>2){
    keyinwk = getch2bbf(wait);
    if(keyinwk==0x03) bkeyin = 0x03;
    else if(keyinwk!=0xffff) { ACIA0RD = keyinwk; ACIA0STS = 0x03; }	// Set RE stutus ......TR
	else ACIA0STS = 0x02;
	ACIA0CHK = 0;
  }
}

char hasctbl[16] = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F',};
void read_battxt(char *txtfnb, int tend, tt_u8 cmd){
  struct stat st;
  FILE *tfp;
  int bfsz, i;
  if (stat(txtfnb, &st) != 0) printf("\n[%s] Not.Found]\n" , txtfnb);
  else {
    txtbufmx = st.st_size;
	if(cmd!='R') bfsz = txtbufmx + 1; else bfsz = txtbufmx * 2 + 1;
	txtbuf = (tt_u8 *)mmalloc(bfsz);
	if ((tfp = fopen( txtfnb, "r+b")) == NULL) printf("[%s Open.Error]", txtfnb);
	else {
	  fread(txtbuf, txtbufmx, 1, tfp);
	  if(cmd=='R'){
	    memcpy( &txtbuf[txtbufmx], &txtbuf[0], txtbufmx);
		for(i=0; i<txtbufmx; i++){
		  txtbuf[i*2  ] = hasctbl[(txtbuf[txtbufmx+i] >> 4)];
		  txtbuf[i*2+1] = hasctbl[txtbuf[txtbufmx+i] & 0x0f];
		}
		txtbufmx = txtbufmx * 2; txtbuf[txtbufmx++] = 0x1a;
	  }
	  if(tend!=0) { *(txtbuf + txtbufmx) = 0x1a; txtbufmx++; } // Add CTRL+Z
	  fclose(tfp);
  	  //printf("[Fn=%s]\n%s",txtfnb,txtbuf);
	  txtbufp = 0;
	}
  }
}

void set_battxt(int tend){
  char txtfnb[256];
  printf("\nFilename = ");
  getkeys(txtfnb); txtfnb[strlen(txtfnb)-1] = 0; // read filename
  read_battxt( txtfnb,tend, ' ');
}

void set_battxt(int tend);
void set_fddtxt();
int check_ctrl(int kdt, int tend){
  if(kdt==0x14) { set_battxt(tend);	return -1; } // CTRL T
  if(kdt==0x06) { set_fddtxt();	return -1; } // CTRL F
  return kdt;
}

void getkeys(char *input){
	int kd,kc=0;
	for(;;) {						// Console.in
		kd = getch2bbf(-1);
		if(kd!=0x08){
			input[kc++] = kd;
			printf("%c", kd); if(kd==0x0d) printf("\n");
		} else {
			if(kc!=0) {	kc--; printf("\x08 \x08"); }// BS
		}
		if(kd==0x0d) { input[kc] = 0; break; }
	}
}

void set_fddtxt(){
  char **fdnpp = (char **)&txtfnb;
  printf("\nDrive.No FDName = ");
  getkeys(txtfnb); txtfnb[strlen(txtfnb)-1] = 0; // read fdname
  get_fddname((char **)&fdnpp);
}

int check_outch(tt_u8 kdt){
static int hwk,hdc;
  //char cmd;
  FILE *tfp;
  static int txtbufoc = -1, txtbufsv = -1;
  if(txtbufsv==2 && txtbufp==-1) {txtbufsv = -1; txtbufcmd = ' '; }
  if(kdt==0) return txtbufsv;
  if(txtbufoc==-1) { 
    if(kdt==0x14 || kdt==0x19 ){	// CTRL + T/Y
	  txtbufocm = kdt;
      txtbufp = -1; free(txtbuf);  // Clear pre
	  txtbufoc = 0; txtbufsv = 1; hwk = 0; hdc = 0;
	  txtbuf = (tt_u8 *)mmalloc(32767);
	}
  } else {
    if(kdt!=0x1a) { 
	  if(txtbufcmd=='W'){
	    if(kdt>='0' && kdt<'g'){
		  if(kdt>'F') kdt = kdt - 0x20; // a -> A
		  kdt = hcnvtbl[kdt-0x30];
		  if(hdc==0) hwk = kdt;
		  else {
		    txtbuf[txtbufoc] = (hwk << 4) + kdt; txtbufoc++; 
		  }
		  hdc = 1 - hdc; // 0 - 1 - 0 - 1
		}
	  } else {
	    txtbuf[txtbufoc] = kdt; txtbufoc++; 	// Set outch.Data to buffer
	  }
	  if(txtbufocm==0x19 && txtbuf[0]!='L' && txtbuf[0]!='S' && txtbuf[0]!='R' && txtbuf[0]!='W'){
	    txtbufp = -1; txtbufoc = -1; txtbufsv = 2; free(txtbuf); 
	  }
	}
	else {
	  txtbuf[txtbufoc] = 0;
	  if(txtbufocm==0x14) { txtbufmx = txtbufoc; txtbufp = 0;  }	// cmd = CTRL+T 
	  else
	  if(txtbufocm==0x19) {											// cmd = CTRL+Y
	    txtbuf[txtbufoc] = 0;  txtbufcmd = txtbuf[0]; txtbufoc = -1;
	    strcpy(txtfnb, (char *)&txtbuf[1]); free(txtbuf);
		//printf("[fn=%s]", txtfnb);
		if(txtbufocm==0x19) {
		  if(txtbufcmd=='L' || txtbufcmd=='R'){
			read_battxt( txtfnb, 0x1a, txtbufcmd);
			txtbufsv = 2;
		  } else
		  if(txtbufcmd=='S' || txtbufcmd=='W'){
	        txtbufocm = 0x18;
            txtbufp = -1; 
	        txtbuf = (tt_u8 *)mmalloc(131072);	// 128KB
	        txtbufoc = 0;
			pausectl = get_memb(0xcc09); set_memb(0xcc09,0);
		  } else {
		    txtbufp = -1; txtbufsv = 2; free(txtbuf); 
		  }
        }
	  } else
	  if(txtbufocm==0x18) {	// Save(asc)/Write(bin)
	    /*
		if(txtbufcmd=='W'){
		  //txtbufoc = txtbufoc / 2;
		  i = 0; j = 0;
		  while(i<txtbufoc-1){
		    if(txtbuf[i]>='0' && txtbuf[i+1]>='0'){
		      txtbuf[j++] = hcnvtbl[txtbuf[i]-'0'] * 16 + hcnvtbl[txtbuf[i+1]-'0'];
			  i = i + 2;
			} else i++;
		  }
		  txtbufoc = j;
		}
		*/
	    //printf("%s\n %d\n", txtbuf, txtbufoc);
		if ((tfp = fopen( txtfnb, "w+b")) == NULL) printf("[%s Open.Error]", txtfnb);
		fseek(tfp, 0, SEEK_SET);
		fwrite(txtbuf, txtbufoc, 1, tfp); 
		fclose(tfp);
	    //printf("Copy %dByte",txtbufoc); //timeout(-1); getch();
		set_memb(0xcc09,pausectl);
		txtbufoc = -1; txtbufocm = 0;
		txtbufsv = 2;
	  }
	}
  }
  return txtbufsv;
}

int Comdly = 0;
tt_u8 brkmemon( tt_u8 mmode, tt_u16 adr, tt_u8 val){
  int brkopr = 0, keyoc;
  tt_u8 fdcmd;
  
  if(adr==0xcc2b || adr==0xcc2c) { 
	if(mode_check()) printf("\n[Break %x %x %x %x]", adr, prepc, mmode, val); 
    val = 0xbf;
	brkopr = 1;
  }
  //
  // ACIA0 MC6850
  //
  if(adr==ACIA0CTR || adr==ACIA0DAT){
    brkopr = 1;
    if(adr==ACIA0DAT){
      if(mmode==0x80){
	    val = ACIA0RD;				// INCH
		ACIA0STS = ACIA0STS & 0xfe;	// Clr RE
		keydtime = 10;
	  } else {
        //if(ra!=0){
		  keyoc = check_outch(ra);
	      if(keyoc==-1 && ra!=0 && ra!=0x1a){ 
			printf("%c", ra); 		// OUTCH	
			keydtime = 10;
		  }
		//}
      }
    }
    if(adr==ACIA0CTR && (mmode&0x80)!=0) {
      if(keydtime>0) keydtime--;
	  else           keyinchk(1);		// CPU Busy suppress
	  val = ACIA0STS; 
	  ACIA0CHK++;
	}
  }
  //
  // MPT
  //
  if(adr==MPT || adr==MPT+1){ brkopr = 1; dmsg("MPT:",adr); }	// No.opreat
  //
  // FD FD1771
  //
  if(adr==FD_Comreg){
    if(mmode==0x80) { 
	  if(Comdly==0) val = FDD_Comreg;
	  else {Comdly--; val = FDD_Comreg & 0xfe; } 
	  brkopr = 1;
	} // R
	else { 
	  //FDD_Comreg = val;
	   fdcmd = val & 0xf0;   							// W
	  if(fdcmd==0x00) { FDD_Trkreg = 0; FDD_Comreg = 0; dmsg("Rest:",val); brkopr = 1;}	// #$0F(0b) RESTORE COMMAND
	  if(fdcmd==0x10) { FDD_Comreg = 0; FDD_Trkreg =FDD_Datreg; dmsg("Seek:",val); brkopr = 1;}	// 18 1B			// Seek ?
	  if(fdcmd==0x80) { 												// #$8* READ SINGLE RECORD(3=Data.Ready)
		if(val==0x8c) Comdly = 0;
		else          Comdly = 10;
		FDD_Comreg = 3; FDD_Dcount = 0; seldrv = FDD_Drvreg;
		if(dbgtest & 0x02) printf("R %x %x %x %x]\n", prepc, FDD_Drvreg, FDD_Trkreg, FDD_Secreg);
		if(FDD_Trkreg==0 && FDD_Trkreg==1) file_read(FDD_Trkreg, 0);			// BooTéûÇæÇØÇÃì¡ï èàóù(512B Read)
		else                               file_read(FDD_Trkreg, FDD_Secreg); 	// Normal(256B Read)
		brkopr = 1;
	  } 
	  if(fdcmd==0xA0) {
		FDD_Comreg = 3; FDD_Dcount = 0; seldrv = FDD_Drvreg;
		dmsg("W.Req:",val); 
		brkopr = 1;
	  }
	}
  }
  //
  if(adr==FD_Drvreg && mmode==0x40) { FDD_Drvreg = val & 0x0f; brkopr = 1; dmsg("W.Drv:",val);} // W
  if(adr==FD_Trkreg && mmode==0x40) { FDD_Trkreg = val; brkopr = 1; dmsg("W.Trc:",val);} // W
  if(adr==FD_Secreg && mmode==0x40) { FDD_Secreg = val; brkopr = 1; dmsg("W.Sec:",val);} // W
  if(adr==FD_Datreg && mmode==0x40) {	// Write 256B
    FDD_Datreg = val; //dmsg("W.Dat:",val);
	file_rwbuf[FDD_Dcount] = val; FDD_Dcount++;
	if(FDD_Dcount==FDD_Dmax) {
	  FDD_Comreg = 0x00;
	  if(dbgtest & 0x02) printf("W %x %x %x]\n", FDD_Drvreg, FDD_Trkreg, FDD_Secreg);
	  file_write(FDD_Trkreg, FDD_Secreg);
	}
    brkopr = 1;
  } 
  if(adr==FD_Datreg && mmode==0x80) {	// Read 256B
    val = file_rwbuf[FDD_Dcount]; FDD_Dcount++;
	//if(FDD_Trkreg==1 && FDD_Trkreg==1) printf("%2x ", val);
	if(FDD_Dcount==FDD_Dmax) FDD_Comreg = 0;
	brkopr = 1; 
  }
  if(adr==FD_Trkreg && mmode==0x80) { val = FDD_Trkreg; brkopr = 1;}
  //
  //
  //
  //if(adr==0xe056) brkopr = 1; // ?
  //if(adr==0xe057) brkopr = 1; // ?
  //
  if(adr==0xc400) { 
    set_memw(0xcc2b, 0xbfff); set_memb(0xcc09, 0); brkopr = 1; } // Set MEMEND($BFFF) PAUSE CONTROL(0)
  //
  if(brkopr==0 && mode_check()){
    if(mmode==0x80) printf("[MR PC:%04X AD:%04X DT:%02X]", prepc, adr, val);
    else            printf("[MW PC:%04X AD:%04X DT:%02X]", prepc, adr, val);
	printf("="); keyinchk(-1);
  }
  return val;
}

char hdbuf[256];
void dumpmf( int adr){
  int i,j;
  FILE *fp;
  fp=fopen("debug.txt","a");
  fprintf(fp,"%s", hdbuf);
  for( i=0; i<8; i++){
    fprintf(fp,"%4X:", adr);
    for(j=0; j<16; j++){
      fprintf(fp," %2X",get_memb(adr++));
    }
    fprintf(fp,"\n");
  }
  fclose(fp);
}
void drive_ctr(){
  tt_u8 dcmd;
  tt_u8 drv, ans;
  int bc;
  char dmsg[256];
  dcmd = rb;
  ra = ry >> 8; rb = ry & 0xff;
  ans = 0x04;
  switch(dcmd){
  	case 0: //sprintf(hdbuf,"READ T=%d S=%d X=%x \n", ra, rb, rx); 
          //int rxw = rx;
	  ans = file_read(ra, rb); 
	  for(bc=0; bc<256; bc++) set_memb(rx++, file_rwbuf[bc]);
          //dumpmf(rxw);
      break;
  	case 1: sprintf(dmsg, "WRITE %d %d", ra, rb); 
	  for(bc=0; bc<256; bc++) file_rwbuf[bc] = get_memb(rx++);
      ans = file_write(ra, rb); break;
  	case 2: sprintf(dmsg, "VERIFY"); 
	  ans = 4; break;
  	case 3: sprintf(dmsg, "RESTORE"); 
	  ans = 4; break;
  	case 4: //sprintf(dmsg, "DRIVE");
	  drv = get_memb(rx+3); sprintf(dmsg, "D%d:", seldrv);
	  if(drv<4) ans = 0x04;
	  else      ans = 0x00;
	  seldrv = drv; break;
  	case 5: sprintf(dmsg, "CHKRDY");
	  drv = get_memb(rx+3);
	  if(drv<4) ans = 0x04; // Z=0 OK
	  else     ans = 0x00;
	  break;
  	case 6: sprintf(dmsg, "QUICK"); 
	  drv = get_memb(rx+3);
	  if(drv<4) ans = 0x04; // Z=0 OK
	  else     ans = 0x00;
	  break;
  	case 7: sprintf(dmsg, "INIT"); 
	  break;
  	case 8: sprintf(dmsg, "WARM"); 
	  break;
  	case 9: sprintf(dmsg, "SEEKIT"); 
	  ans = 4; break;
  }
  if(ddskmsg && dcmd==1) printf("%s", dmsg);
 setcc(ans);
}

int m6809_swi_call(void) 
{
  static char input[256];
  char *p = input;
  tt_u8 c;
  int kin;

  switch (ra) {
  case 0 :
    printf("Program terminated\n");
    rti();
    return 1;
  case 1 :
    while ((c = get_memb(rx++)))
      putchar(c);
    rti();
    return 0;
  case 2 :
    ra = 0;
    if (rb) {
      fflush(stdout);
      if (fgets(input, rb+1, stdin)) {
	    do {
	      set_memb(rx++, *p);
	      ra++;
	    } while (*p++);
	    ra--;
      } else
	set_memb(rx, 0);
    }
    set_memb(rs + 1, ra);
    rti();
    return 0;
  case 3 :			// Reg.B=GETCH()
	rti();
  	//timeout(-1);	// Wait For Key.in
	//kin = getch(); 
	kin = getch2bbf(-1);
	if(kin==0x03 || kin==0x06 || kin==0x14) bkeyin = kin;
	rb = kin;
    return 0;
  case 4 :			// PUTCH(Reg.B)
	if(rb!=0){
	  kin = check_outch(rb);
	  if(kin==-1 && rb!=0 && rb!=0x1a){
	    putchar(rb); fflush(stdout);
      }
	}
	rti();
    return 0;
  case 5 :			// KBHIT()
	rti();
  	//timeout(0);		// NO.Wait For Key.in
	//kin = getch(); 
	kin = getch2bbf(0);
	if(kin==-1) kin = 0;	// 
	if(kin<0x0a) bkeyin = kin;
	rb = kin;
    return 0;
  case 6:	// DRIVERS Control
	rti();
	drive_ctr();
	return 0;
  case 254:			// Pass & Disp
    rti();
	printf("\n!Pass "); dis6809(rpc, stdout);
	return 0;
  case 255:			// Break
    rti();
	printf("\n!Break "); dis6809(rpc, stdout);
	return 1;
  default :
    printf("Unknown system call %d\n", ra);
    rti();
    return 0;
  }
}
