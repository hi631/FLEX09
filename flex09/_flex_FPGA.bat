echo off
rem goto DOSIM
rem goto DOASM2LIST

echo �A�Z���u�����s INIT.ASM
..\bin\msdos.exe ..\bin\as09xx.exe INIT.ASM  -l > INIT.LST
if %errorlevel% == 1 GOTO ERR
echo �A�Z���u�����s SPOOLER.ASM
..\bin\msdos.exe ..\bin\as09xx.exe SPOOLER.ASM  > NUL
if %errorlevel% == 1 GOTO ERR
echo �A�Z���u�����s FLX29CCP.ASM
..\bin\msdos.exe ..\bin\as09xx.exe FLX29CCP.ASM  > NUL
if %errorlevel% == 1 GOTO ERR
echo �A�Z���u�����s FLX29FMS.ASM
..\bin\msdos.exe ..\bin\as09xx.exe FLX29FMS.ASM  > NUL
if %errorlevel% == 1 GOTO ERR
echo �A�Z���u�����s DRIVERS.ASM
..\bin\msdos.exe ..\bin\as09xx.exe DRIVERS.ASM  > NUL
if %errorlevel% == 1 GOTO ERR
echo �A�Z���u�����s CONSOLE.ASM
..\bin\msdos.exe ..\bin\as09xx.exe CONSOLE_FPGA.ASM -l > CONSOLE.LST
if %errorlevel% == 1 GOTO ERR
type console.lst
goto DOCONV

:DOASM2LIST
echo ** ���X�g�쐬�� **
echo �A�Z���u�����s INIT.ASM
..\bin\msdos.exe ..\bin\as09xx.exe INIT.ASM -l > INIT.LST
if %errorlevel% == 1 GOTO ERR
echo �A�Z���u�����s SPOOLER.ASM
..\bin\msdos.exe ..\bin\as09xx.exe SPOOLER.ASM -l > SPOOLER.LST
if %errorlevel% == 1 GOTO ERR
echo �A�Z���u�����s FLX29CCP.ASM
..\bin\msdos.exe ..\bin\as09xx.exe FLX29CCP.ASM -l > FLX29CCP.LST
if %errorlevel% == 1 GOTO ERR
echo �A�Z���u�����s FLX29FMS.ASM
..\bin\msdos.exe ..\bin\as09xx.exe FLX29FMS.ASM -l > FLX29FMS.LST
if %errorlevel% == 1 GOTO ERR
echo �A�Z���u�����s DRIVERS.ASM
..\bin\msdos.exe ..\bin\as09xx.exe DRIVERS.ASM -l > DRIVERS.LST
if %errorlevel% == 1 GOTO ERR
echo �A�Z���u�����s CONSOLE.ASM
..\bin\msdos.exe ..\bin\as09xx.exe CONSOLE_FPGA.ASM -l > CONSOLE.LST
if %errorlevel% == 1 GOTO ERR

:DOCONV
copy INIT.s19 + SPOOLER.s19 + FLX29CCP.s19 + FLX29FMS.s19 + DRIVERS.s19 + CONSOLE_FPGA.s19 flex9.s1
..\bin\mot2hex flex9 > NUL

NOTEPAD FLEX9.HEX

goto END
:ERR
echo ****************************
echo *  �A�Z���u���ɃG���[�L��  *
echo ****************************
:END
timeout 3

GOTO SKIPEND
echo ****************************
echo *  �ȉ��̓���              *
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
SPOOLER   C700 - C7FC  (�d��)
FLEX29CCP CC00 - D3FF  C840 .. Staart.Msg(�d��)
FLEX29FMS D400 - DDF2
DRIVERS   DE00 - F3BE
CONSOLE   F800 - FFFF  �R���\�[�����t�@�C��

:SKIPEND
