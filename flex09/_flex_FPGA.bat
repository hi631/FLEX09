echo off
rem goto DOSIM
rem goto DOASM2LIST

echo アセンブル実行 INIT.ASM
..\bin\msdos.exe ..\bin\as09xx.exe INIT.ASM  -l > INIT.LST
if %errorlevel% == 1 GOTO ERR
echo アセンブル実行 SPOOLER.ASM
..\bin\msdos.exe ..\bin\as09xx.exe SPOOLER.ASM  > NUL
if %errorlevel% == 1 GOTO ERR
echo アセンブル実行 FLX29CCP.ASM
..\bin\msdos.exe ..\bin\as09xx.exe FLX29CCP.ASM  > NUL
if %errorlevel% == 1 GOTO ERR
echo アセンブル実行 FLX29FMS.ASM
..\bin\msdos.exe ..\bin\as09xx.exe FLX29FMS.ASM  > NUL
if %errorlevel% == 1 GOTO ERR
echo アセンブル実行 DRIVERS.ASM
..\bin\msdos.exe ..\bin\as09xx.exe DRIVERS.ASM  > NUL
if %errorlevel% == 1 GOTO ERR
echo アセンブル実行 CONSOLE.ASM
..\bin\msdos.exe ..\bin\as09xx.exe CONSOLE_FPGA.ASM -l > CONSOLE.LST
if %errorlevel% == 1 GOTO ERR
type console.lst
goto DOCONV

:DOASM2LIST
echo ** リスト作成中 **
echo アセンブル実行 INIT.ASM
..\bin\msdos.exe ..\bin\as09xx.exe INIT.ASM -l > INIT.LST
if %errorlevel% == 1 GOTO ERR
echo アセンブル実行 SPOOLER.ASM
..\bin\msdos.exe ..\bin\as09xx.exe SPOOLER.ASM -l > SPOOLER.LST
if %errorlevel% == 1 GOTO ERR
echo アセンブル実行 FLX29CCP.ASM
..\bin\msdos.exe ..\bin\as09xx.exe FLX29CCP.ASM -l > FLX29CCP.LST
if %errorlevel% == 1 GOTO ERR
echo アセンブル実行 FLX29FMS.ASM
..\bin\msdos.exe ..\bin\as09xx.exe FLX29FMS.ASM -l > FLX29FMS.LST
if %errorlevel% == 1 GOTO ERR
echo アセンブル実行 DRIVERS.ASM
..\bin\msdos.exe ..\bin\as09xx.exe DRIVERS.ASM -l > DRIVERS.LST
if %errorlevel% == 1 GOTO ERR
echo アセンブル実行 CONSOLE.ASM
..\bin\msdos.exe ..\bin\as09xx.exe CONSOLE_FPGA.ASM -l > CONSOLE.LST
if %errorlevel% == 1 GOTO ERR

:DOCONV
copy INIT.s19 + SPOOLER.s19 + FLX29CCP.s19 + FLX29FMS.s19 + DRIVERS.s19 + CONSOLE_FPGA.s19 flex9.s1
..\bin\mot2hex flex9 > NUL

NOTEPAD FLEX9.HEX

goto END
:ERR
echo ****************************
echo *  アセンブルにエラー有り  *
echo ****************************
:END
timeout 3

GOTO SKIPEND
echo ****************************
echo *  以下はメモ              *
echo ****************************

Memory
0000 - BFFF User RAM *Note: Some of this space is used by NEWDISK, COPY and the printer utilities.
C000 - C07F System stack
C080 - COFF Line Input Buffer
C100 - C6FF Utility command space
C700 - DFFF Disk Operating System
CD00/03     FLEX cold/warm start entry address

Asmb Files
INIT      C400 - C951
SPOOLER   C700 - C7FC  (重複)
FLEX29CCP CC00 - D3FF  C840 .. Staart.Msg(重複)
FLEX29FMS D400 - DDF2
DRIVERS   DE00 - F3BE
CONSOLE   F800 - FFFF  コンソール＆ファイル

:SKIPEND
