--  SIM  -------------------------------

DELETE TEST.C
YY
EDIT TEST.C
mjump(adr) int adr;{
  int (* func)();
  func = adr; (* func)();
}
char buf[16];
main(){
  unsigned int adr;
  printf("jamp = $"); scanf("%x", &adr);
  if(adr==0) adr=0xD24B;
  /* movmem(0xd000, buf, 16); */
  mjump(adr); /* D24B CAN'T TRANSFER */
}
#
S

ICC TEST.C -r
ILINK TEST.R



DELETE TEST.C
YY
EDIT TEST.C
  main()
  {
   int i;
   char buf[256];
   printf("hello\n");
   movmem(0xD000, buf, 0x10);
   for(i=0; i<16; i++){
     printf("%02X ", buf[i]);
   }
  }
#
S

ICC TEST.C -r
ILINK TEST.R



DELETE TEST.C
YY
EDIT TEST.C
int *jb;
int jbwk[2];
char buf[256];
main()
{
	int i;
	jb=jbwk;
    if( setjmp( jb ) == 0 ) {
		 movmem(jbwk[0], buf, 16);
		 for( i=0; i<16; i++) printf("%02X ", buf[i]);
         printf("\nlongjump %04x %4x %4x\n", jb, jbwk[0], jbwk[1]);
		 for(;;)
		 	longjmp( jb, 1 );
    } else {
        printf("setjump(,1)\n");
    }
}
#
S

ICC TEST.C -r
ILINK TEST.R
TEST.1


--  FPGA  --------------------------------------------

DELETE TEST.C
    Y
 Y
   EDIT TEST.C
    
   main()
   {
     int i,j;
     char *cp;
     printf("MEM.DUMP\n");
     cp = 0xf200;
     for(j=0;j<8;j++){
       printf("\n%04x:",cp);
       for(i=0; i<16; i++){
         printf(" %02X", *(cp));
         cp++;
       }
     }
   }
#S
  ICC TEST.C -r
              ILINK TEST.R
        TEST.1


