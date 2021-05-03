..\bin\msdos ..\bin\as09xx monitor.asm -l > monitor.lst
del monitor.s1
rename monitor.s19 monitor.s1
..\bin\mot2hex monitor
type monitor.lst
NOTEPAD monitor.hex
timeout 3
