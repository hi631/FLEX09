#include <stdio.h>

int bin2hex(int addr, char *fn1, char *fn2) {
    int n, i, chk;
    FILE *fp1, *fp2;
    char buff[16];

    if ((fp1=fopen(fn1,"rb"))==NULL) { printf("Can't open %s\n",fn1); return 1; }
    if ((fp2=fopen(fn2,"w"))==NULL) { printf("Can't create %s\n",fn2); return 1; }

    while ((n=fread(buff,1,16,fp1)) > 0) {
        fprintf(fp2,":%02X%04X00",n,addr);
        for (chk=n+(addr/256)+(addr%256), i=0; i<n; i++) {
            fprintf(fp2,"%02X",buff[i]&0xFF);
            chk+=buff[i];
        }
        fprintf(fp2,"%02X\n",(0x100 - (chk&0xFF))&0xFF);
        addr+=n;
    }
    fprintf(fp2,":00000001FF\n");
    
    fclose(fp1); fclose(fp2);
	return 0;
}

int bin2hexw(char md, char *fn1, char *fn2) {
    int n, i, chk;
    FILE *fp1, *fp2;
    char buff[16];

	if(md!='w') { printf("Option.Error"); return 1; }

    if ((fp1=fopen(fn1,"rb"))==NULL) { printf("Can't open %s\n",fn1); return 1; }
    if ((fp2=fopen(fn2,"w"))==NULL) { printf("Can't create %s\n",fn2); return 1; }

	int addr = 0;
    while ((n=fread(buff,1,2,fp1)) > 0) {
        fprintf(fp2,":%02X%04X00",n,addr);
        for (chk=n+(addr/256)+(addr%256), i=0; i<n; i++) {
            fprintf(fp2,"%02X",buff[i]&0xFF);
            chk+=buff[i];
        }
        fprintf(fp2,"%02X\n",(0x100 - (chk&0xFF))&0xFF);
        addr+=(n/2);
    }
    fprintf(fp2,":00000001FF\n");
    
    fclose(fp1); fclose(fp2);
    return 0;
}


int main(int argc, char *argv[]) {
    int addr;

    switch (argc) {
    case 3: //sscanf(argv[3],"%x",&addr);
            bin2hex( 0,argv[1],argv[2]);
            return 0;
    case 4:
            bin2hexw(*argv[3],argv[1],argv[2]);
            return 0;
    }

    printf("Usage: bin2hex file.bin file.hex\n");
    printf("eg   : bin2hex boot.bin boot.hex w // Altera 16bit\n");
    return 1;
}
