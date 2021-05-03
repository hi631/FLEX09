..\bin\msdos ..\bin\as09xx basic.asm -l > basic.lst
..\bin\mot2bin basic.s19
..\bin\bin2hexw basic.bin basic.hex
COPY BASIC.HEX C:\kitahard\EP2C5_MINI\flex09\ROMS\6809\BASIC.HEX
NOTEPAD BASIC.LST
timeout 3