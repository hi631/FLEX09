`default_nettype none
module Microcomputer(
	input				clk_50M,
	// SRAM
	output [18:0] 	SRAMAD,
	inout   [7:0]  SRAMIO,
	output			SRAMCEn,SRAMWEn,SRAMOEn,
	// SDCARD
	output 			sdCS, sdMOSI, sdSCLK,		// CS SCK MOSI
	input  			sdMISO,							// MISO(pullup)
	// I/O
	input				rxd1,cts1,vcc1,				// vcc1(dumy)
	output			txd1,rts1,
	input    [0:0]	BTN,
	output	[2:0]	LED
	);

	wire			n_WR, n_RD;
	wire	[15:0] cpuAddress;
	wire	[7:0]	cpuDataOut, cpuDataIn;
	wire	[7:0]	sysRomDataout;
	wire	[7:0]	intRamDataOut;
	wire	[7:0]	sdCardDataOut;
	wire	[7:0]	serialDataOut;
	wire			locked,sdclk;
	wire			driveLED;
	//  external SRAM Connect
	assign	SRAMAD   = {3'b000,cpuAddress[15:0]};
	assign	SRAMIO   = (n_memWR == 1'b0) ? (cpuDataOut) : ({(7 - 0 + 1){1'bZ}});
	assign	SRAMWEn	= n_memWR | n_extRamCS;
	assign	SRAMOEn	= n_memRD | n_extRamCS;
	assign	SRAMCEn	= n_extRamCS;
	// LED
	assign LED[2] = romInhib;
	assign LED[1] = 1; 
	assign LED[0] = driveLED;

	// Clock generate
	clkgen	clkgen_inst (
		.inclk0 (clk_50M), .c0 (cpuClockx2), .c1 (sdclk), .c2 (), .locked ( locked ) );
	// MPU 6809
	cpu09p	cpu1 (
		.clk(cpuClock), .rst_n(n_reset), .rw(n_WR), .vma(),
		.addr(cpuAddress), .data_in(cpuDataIn), .data_out(cpuDataOut),
		.halt(1'b0), .hold(1'b0), .irq(1'b0), .firq(1'b0), .nmi(1'b0) );

	// 8KB BASIC
	M6809_EXT_BASIC_ROM	rom1 (
		.clock(cpuClockx2), .address(cpuAddress[12:0]), .q(sysRomDataout) );
	// 2K RAM (Internal)
		InternalRam2K	ram1 (
		.clock(cpuClockx2), .wren( ~(n_memWR | n_intRamCS)),
		.address(cpuAddress[10:0]), .data(cpuDataOut), .q(intRamDataOut) );
	// SERIAL I/O
	bufferedUART	io1 (
		.clk(cpuClock),
		.n_wr(n_serialCS | n_memWR), .n_rd(n_serialCS | n_memRD),
		.n_int(), .regSel(cpuAddress[0]),
		.dataIn(cpuDataOut), .dataOut(serialDataOut),
		.rxClock(serialClock), .txClock(serialClock),
		.rxd(rxd1),	.txd(txd1), .n_cts(1'b0), .n_dcd(1'b0) , .n_rts(rts1) );
	// SDCARD Control
	sd_controller sd1 (
		.sdCS(sdCS), .sdMOSI(sdMOSI), .sdMISO(sdMISO), .sdSCLK(sdSCLK),
		.n_reset(n_reset), .clk(sdclk),
		.n_wr(n_sdCardCS | n_memWR), .n_rd(n_sdCardCS | n_memRD),
		.regAddr(cpuAddress[2:0]), .dataIn(cpuDataOut), .dataOut(sdCardDataOut),
		.driveLED(driveLED)
	);

	wire n_reset  = locked && BTN[0];
	wire n_memRD  = ~( ~(cpuClock) & n_WR);
	wire n_memWR  = ~( ~(cpuClock) & ( ~n_WR));
	wire romInhib = sys_ctrl == 8'h81 ? 1'b1 : 1'b0;

	wire n_sysRomCS = (cpuAddress[15] == 1 && cpuAddress[13] == 1 && romInhib == 0) ? 0 : 1;	//8KB at E000 - FFFF /A000 - BFFF
	wire n_extRamCS = 0;	
	wire n_intRamCS = 1;//(cpuAddress[15:11] == 5'b00000) ? 0 : 1; 	// 2 KB 0000 - 07FF
	wire n_serialCS = (cpuAddress[15:1] == {12'hFFD,3'b000}) ? 0 : 1;	// 2 Bytes FFD0 - 1
	wire n_sdCardCS = (cpuAddress[15:3] == {12'hFFD,1'b1})   ? 0 : 1;	// 8 Bytes FFD8 - F

	assign cpuDataIn = 
				  (n_serialCS == 1'b0) ? (serialDataOut)
				: (n_sdCardCS == 1'b0) ? (sdCardDataOut)
				: (n_sysRomCS == 1'b0) ? (sysRomDataout)
				: (n_intRamCS == 1'b0) ? (intRamDataOut)
				: (n_extRamCS == 1'b0) ? (SRAMIO)
				: (8'hFF);

	wire 	 cpuClock,cpuClockx2;
	reg	 cpuClockx1;
	assign cpuClock  = cpuClockx1;
	always @(posedge cpuClockx2) begin cpuClockx1 <= !cpuClockx1;	end
	
	reg [7:0] sys_ctrl;
	always @(posedge cpuClock) begin
	   if(n_reset==0) sys_ctrl <= 8'h00;
		else
	     if(cpuAddress[15:0]==16'hffff && n_memWR==1'b0) sys_ctrl <= cpuDataOut;
   end	

	reg [15:0]	serialClkCount;
	wire	serialClock;
	assign	serialClock	= serialClkCount[15];
	always @(posedge clk_50M) begin
		serialClkCount	<= serialClkCount + 2416;
	end
endmodule
`default_nettype wire
