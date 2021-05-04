<p><b><font size="+1"><span class="VIiyi" jsaction="mouseup:BR6jm" jsname="jqKxS" lang="en" style="-webkit-tap-highlight-color: transparent; display: inline; color: rgb(0, 0, 0); font-family: Roboto, RobotoDraft, Helvetica, Arial, sans-serif; font-size: 24px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: start; text-indent: 0px; text-transform: none; white-space: pre-wrap; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; background-color: rgb(245, 245, 245); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><span jsaction="agoMJf:PFBcW;usxOmf:aWLT7;jhKsnd:P7O7bd,F8DmGf;Q4AGo:Gm7gYd,qAKMYb;uFUCPb:pvnm0e,pfE8Hb,PFBcW;f56efd:dJXsye;EnoYf:KNzws,ZJsZZ,JgVSJc;zdMJQc:cCQNKb,ZJsZZ,zchEXc;Ytrrj:JJDvdc;tNR8yc:GeFvjb;oFN6Ye:hij5Wb" jscontroller="Zl5N8" jsmodel="SsMkhd" jsname="txFAF" class="JLqJ4b ChMk0b" data-language-for-alternatives="en" data-language-to-translate-into="ja" data-phrase-index="0" jsdata="uqLsIf;_;$7" style="-webkit-tap-highlight-color: transparent; cursor: pointer;"><span jsaction="click:qtZ4nf,GFf3ac,tMZCfe; contextmenu:Nqw7Te,QP7LD; mouseout:Nqw7Te; mouseover:qtZ4nf,c2aHje" jsname="W297wb" style="-webkit-tap-highlight-color: transparent;">Make 6809 with FPGA and run FLEX</span></span></span><span style="color: rgb(0, 0, 0); font-family: Roboto, RobotoDraft, Helvetica, Arial, sans-serif; font-size: 24px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: start; text-indent: 0px; text-transform: none; white-space: pre-wrap; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; background-color: rgb(245, 245, 245); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; display: inline !important; float: none;"> </span></font></b></p>
<p><font size="+1">#Simulator (SIM6809)</font><br>
<a>original material</a>[<a href="https://github.com/gordonjcp/sim6809">SIM6809</a>]<br>
SIM6809 is compiled with MINGW32.<br>
Start MINGW32 and move to the source directory with &quot;cd / C / ...... / sim6809&quot;,<br>
Compile with one make, start with &quot;./sim6809&quot; and the prompt should appear.<br>
<br>
<font size="+1"># FLEX</font><br>
Portable by adding serial and SD drivers to DRIVER (file is CONSOLE).<br>
The OS is localized to  $ C000-  $ FFFF, and it may not be possible to
move. The user area is 48KB.<br>
Add necessary processing (input / output) and check the operation of the assembled HEX with the simulator.<br>
<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/159764/7c75402f-bf07-3757-a9c0-0a0f8d45fff9.jpeg" border="0" width="471" height="321"><br>
There is a sample of access to the SD card at [<a href="https://github.com/nealcrook/multicomp6809">MULTICOMP6809</a>].<br>
However, FLEX has 256 bytes / sector, while SD card has 512 bytes / sector.<br>
The sample was a method that did not use half of the 512 bytes, but it was divided R / W using a buffer.<br>
<br>
Batch job &quot;_flex_SIM.bat&quot; creates HEX for the simulator.<br>
* Drive is R / W for files on Windows.<br>
Batch job &quot;_flex_FPGA.bat&quot; creates HEX for FPGA.<br>
* The drive is R / W by dividing the SD card.<br>
<br>
Furthermore, since it does not work under windows already, use an extender called msdos.exe.<br>
[<a href="http://takeda-toshiya.my.coocan.jp/msdos/">MS-DOS Player for Win32-x64</a>] <br>
<br>
<font size="+1"># FPGA6809 hard</font><br>
It would be easier to understand the configuration by looking at [<a href="http://searle.x10host.com/Multicomp/index.html">Grant's MULTICOMP</a>].<br>
* Almost as it is. However, VHDL is converted to verilog.<br>
6809 is operating at 30MHz.<br>
The SD card gives the driver 20MHz, so it probably works at 10MHz.<br>
<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/159764/349804fc-e164-1811-e8b5-367e0770675c.jpeg" border="0" width="471" height="321"><br>
Green is EP2C5 mounted board, black and big is FPGA<br>
The board on it is a board with RAM and SD made by CNC<br>
The lower right is the serial board (commercially available FTD1232)<br>
The upper right is the VGA output and PS2 input board (not connected in this software)<br>
<br>
<font size="+1">#FPGA6809 software</font><br>
The software can be compiled with quartus II.<br>
EP2C5 is an old generation Cyclone II, so be careful as it can only be compiled before 13.0sp1.<br>
1. If you want to run BASIC, assemble basic.asm.<br>
2. If you want to run monitor, assemble monitor.asm.<br>
* Both generate basic.hex, so there is no need to change the verilog side.<br>
<br>
<font size="+1">#Monitor program</font><br>
Used for starting FLEX and debugging when FLEX does not start.<br>
Starting FLEX is<br>
1. After starting the monitor, press'B'+'Ret' to start. (Pre-setting required)<br>
2. It is also possible to start from BASIC, and'%' is displayed by'Ctrl' +'L', so copy and paste the FLEX HEX file on the screen.<br>
Automatically start after the message &quot;% %%% ...&quot; is displayed<br>
* It is assumed that basic.asm (modified version) under the moni09 directory is used. It will be started from \ $ C400.<br>
The monitor is localized in two places,  $ E000 and \  A000, and starts
as  $ A000 at the time of reset.<br>
After copying itself to the RAM of \  A000, invalidate the ROM and free
up the FLEX load area.<br>
<br>
<font size="+1">#Drive layout on SD card</font><br>
0000-059F drive 0<br>
05A0 --05CF boot loader<br>
0800-0D9F drive 1<br>
1000-159F drive 2<br>
1800-1D9F drive 3<br>
* Described as 512B / S<br>
* 4 units can be selected, but the 4th unit cannot be used. (I feel like it's 3 in FLEX)<br>
For Card Day, use the command as shown below to combine the disks and write to SD with win32diskimager.<br>
Copy /b FLEX9SYS.DSK + DUMY_4CKFF.bin + BLANK.DSK + DUMY_4CKFF.bin + BLANK.DSK + DUMY_4CKFF.bin SD4M.img<br>
* Obtain FLEX9SYS.DSK from [<a href="http://www.evenson-consulting.com/swtpc/">SWTPC</a>]. I don't think there were any particular restrictions on use.<br>
<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/159764/d2ff437a-967f-e79b-c445-35f715b8c79c.jpeg" border="0" width="471" height="321"><br>
<br>
<font size="+1">#Boot loader settings</font><br>
1. The monitor starts by resetting.<br>
2. Issue the'L'command. Check the'%' display.Copy and paste <br>
3.flex9.hexe to the terminal and load it into memory. (Written to $ C000-
$ FFFF)<br>
4. Issue a write command with'W 5001 C000 3F'.<br>
* 5001 is equivalent to  $ 800 sector (512B / S conversion) on the card.<br>
5. Confirm the operation with the'B'command.<br>
<br>
<a href="https://qiita.com/hi631/items/5b386fb230afcc87c66d">Here is</a> a little more detailed explanation (but in Japanese) <br>
<br>
</p>
