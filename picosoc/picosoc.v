/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Claire Xenia Wolf <claire@yosyshq.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 * 
 */

`ifndef PICORV32_REGS
//`ifdef PICORV32_V
//`error "picosoc.v must be read before picorv32.v!"
//`endif

`define PICORV32_REGS picosoc_regs
`endif

`ifndef PICOSOC_MEM
`define PICOSOC_MEM picosoc_mem
`endif

// this macro can be used to check if the verilog files in your
// design are read in the correct order.
`define PICOSOC_V

module picosoc (
	input clk,
	input resetn,

	/*output        iomem_valid,
	input         iomem_ready,
	output [ 3:0] iomem_wstrb,
	output [31:0] iomem_addr,
	output [31:0] iomem_axi_wdata,
	input  [31:0] iomem_axi_rdata,*/
	
	input  irq_5,
	input  irq_6,
	input  irq_7,

	output ser_tx,
	input  ser_rx
	/*
	output flash_csb,
	output flash_clk,

	output flash_io0_oe,
	output flash_io1_oe,
	output flash_io2_oe,
	output flash_io3_oe,

	output flash_io0_do,
	output flash_io1_do,
	output flash_io2_do,
	output flash_io3_do,

	input  flash_io0_di,
	input  flash_io1_di,
	input  flash_io2_di,
	input  flash_io3_di*/
);
	parameter [0:0] BARREL_SHIFTER = 1;
	parameter [0:0] ENABLE_MUL = 1;
	parameter [0:0] ENABLE_DIV = 1;
	parameter [0:0] ENABLE_FAST_MUL = 0;
	parameter [0:0] ENABLE_COMPRESSED = 1;
	parameter [0:0] ENABLE_COUNTERS = 1;
	parameter [0:0] ENABLE_IRQ_QREGS = 0;

	parameter integer MEM_WORDS = 1024;
	parameter [31:0] STACKADDR = (4*MEM_WORDS);       // end of memory
	parameter [31:0] PROGADDR_RESET = 32'h 0010_0000; // 1 MB into flash
	parameter [31:0] PROGADDR_IRQ = 32'h 0000_0000;

	reg [31:0] irq;
	wire irq_stall = 0;
	wire irq_uart = 0;

	always @* begin
		irq = 0;
		irq[3] = irq_stall;
		irq[4] = irq_uart;
		irq[5] = irq_5;
		irq[6] = irq_6;
		irq[7] = irq_7;
	end

	wire mem_valid;
	wire mem_instr;
	wire mem_ready;
	wire mem_axi_arvalid;
	wire mem_axi_arready;
	wire mem_axi_rvalid;
	wire mem_axi_rready;
	wire mem_axi_awvalid;
	wire mem_axi_awready;
	wire mem_axi_bready;
	wire mem_axi_bvalid;
	wire mem_axi_wvalid;
	wire mem_axi_wready;
	wire mem_axi_awprot;
	wire mem_axi_arprot;
	wire eoi;
	wire trap;
	wire [3 : 0] mem_axi_wstrb;
	wire [31:0] mem_axi_araddr;
	wire [31:0] mem_axi_awaddr;
	wire [31:0] mem_axi_wdata;
	wire [3:0] mem_wstrb;
	wire [31:0] mem_axi_rdata;

	wire mem_axi_ram_awvalid;
	wire mem_axi_ram_awready;
	wire [31 : 0] mem_axi_ram_awaddr;
	wire [2 : 0] mem_axi_ram_awprot;
	wire mem_axi_ram_wvalid;
	wire mem_axi_ram_wready;
	wire [31 : 0] mem_axi_ram_wdata;
	wire [3 : 0] mem_axi_ram_wstrb;
	wire mem_axi_ram_bvalid;
	wire mem_axi_ram_bready;
	wire mem_axi_ram_arvalid;
	wire mem_axi_ram_arready;
	wire [31 : 0] mem_axi_ram_araddr;
	wire [2 : 0] mem_axi_ram_arprot;
	wire mem_axi_ram_rvalid;
	wire mem_axi_ram_rready;
	wire [31 : 0] mem_axi_ram_rdata;
	wire mem_axi_peri_awvalid;
	wire mem_axi_peri_awready;
	wire [31 : 0] mem_axi_peri_awaddr;
	wire [2 : 0] mem_axi_peri_awprot;
	wire mem_axi_peri_wvalid;
	wire mem_axi_peri_wready;
	wire [31 : 0] mem_axi_peri_wdata;
	wire [3 : 0] mem_axi_peri_wstrb;
	wire mem_axi_peri_bvalid;
	wire mem_axi_peri_bready;
	wire mem_axi_peri_arvalid;
	wire mem_axi_peri_arready;
	wire [31 : 0] mem_axi_peri_araddr;
	wire [2 : 0] mem_axi_peri_arprot;
	wire mem_axi_peri_rvalid;
	wire mem_axi_peri_rready;
	wire [31 : 0] mem_axi_peri_rdata;
	wire mem_axi_cpu_awvalid;
	wire mem_axi_cpu_awready;
	wire [31 : 0] mem_axi_cpu_awaddr;
	wire [2 : 0] mem_axi_cpu_awprot;
	wire mem_axi_cpu_wvalid;
	wire mem_axi_cpu_wready;
	wire [31 : 0] mem_axi_cpu_wdata;
	wire [3 : 0] mem_axi_cpu_wstrb;
	wire mem_axi_cpu_bvalid;
	wire mem_axi_cpu_bready;
	wire mem_axi_cpu_arvalid;
	wire mem_axi_cpu_arready;
	wire [31 : 0]mem_axi_cpu_araddr;
	wire [2 : 0] mem_axi_cpu_arprot;
	wire mem_axi_cpu_rvalid;
	wire mem_axi_cpu_rready;
	wire [31 : 0] mem_axi_cpu_rdata;
	wire [1 : 0] mem_axi_peri_bresp;
	wire [1 : 0] mem_axi_peri_rresp;

	//wire spimem_ready;
	//wire [31:0] spimem_axi_rdata;

	//reg ram_ready;
	//wire [31:0] ram_rdata;

	/*assign iomem_valid = mem_valid && (mem_addr[31:24] > 8'h 01);
	assign iomem_wstrb = mem_wstrb;
	assign iomem_addr = mem_addr;
	assign iomem_axi_wdata = mem_axi_wdata;

	wire spimemio_cfgreg_sel = mem_valid && (mem_addr == 32'h 0200_0000);
	wire [31:0] spimemio_cfgreg_do;

	wire        simpleuart_reg_div_sel = mem_valid && (mem_addr == 32'h 0200_0004);
	wire [31:0] simpleuart_reg_div_do;

	wire        simpleuart_reg_dat_sel = mem_valid && (mem_addr == 32'h 0200_0008);
	wire [31:0] simpleuart_reg_dat_do;
	wire        simpleuart_reg_dat_wait;

	assign mem_ready = (iomem_valid && iomem_ready) || spimem_ready || ram_ready || spimemio_cfgreg_sel ||
			simpleuart_reg_div_sel || (simpleuart_reg_dat_sel && !simpleuart_reg_dat_wait);
	
	assign mem_axi_rdata = (iomem_valid && iomem_ready) ? iomem_axi_rdata : spimem_ready ? spimem_axi_rdata : ram_ready ? ram_rdata :
			spimemio_cfgreg_sel ? spimemio_cfgreg_do : simpleuart_reg_div_sel ? simpleuart_reg_div_do :
			simpleuart_reg_dat_sel ? simpleuart_reg_dat_do : 32'h 0000_0000;
	*/

	
	picorv32_axi #(
		.ENABLE_COUNTERS(ENABLE_COUNTERS),
		.BARREL_SHIFTER(BARREL_SHIFTER),
		.ENABLE_MUL(ENABLE_MUL),
		.ENABLE_FAST_MUL(ENABLE_FAST_MUL),
		.ENABLE_DIV(ENABLE_DIV),
		.ENABLE_IRQ(1),
		.ENABLE_IRQ_QREGS(ENABLE_IRQ_QREGS),
		.PROGADDR_RESET(16),
		.PROGADDR_IRQ(PROGADDR_IRQ),
		.STACKADDR(STACKADDR),
		.ENABLE_TRACE(0)
	) picorv32_axi_instance (
		.clk(clk),
		.resetn(resetn),
		.trap(trap),
		.mem_axi_awvalid(mem_axi_cpu_awvalid),
		.mem_axi_awready(mem_axi_cpu_awready),
		.mem_axi_awaddr(mem_axi_cpu_awaddr),
		.mem_axi_awprot(mem_axi_cpu_awprot),
		.mem_axi_wvalid(mem_axi_cpu_wvalid),
		.mem_axi_wready(mem_axi_cpu_wready),
		.mem_axi_wdata(mem_axi_cpu_wdata),
		.mem_axi_wstrb(mem_axi_cpu_wstrb),
		.mem_axi_bvalid(mem_axi_cpu_bvalid),
		.mem_axi_bready(mem_axi_cpu_bready),
		.mem_axi_arvalid(mem_axi_cpu_arvalid),
		.mem_axi_arready(mem_axi_cpu_arready),
		.mem_axi_araddr(mem_axi_cpu_araddr),
		.mem_axi_arprot(mem_axi_cpu_arprot),
		.mem_axi_rvalid(mem_axi_cpu_rvalid),
		.mem_axi_rready(mem_axi_cpu_rready),
		.mem_axi_rdata(mem_axi_cpu_rdata),
		.irq(irq),
		.eoi(eoi)
	);

	picosoc_dec #(
		.mem_words(MEM_WORDS),
		.addr_num(4)
	) picosoc_dec_instance (
		.clk(clk),
		.mem_axi_cpu_awvalid(mem_axi_cpu_awvalid),
		.mem_axi_cpu_awready(mem_axi_cpu_awready),
		.mem_axi_cpu_awaddr(mem_axi_cpu_awaddr),
		.mem_axi_cpu_awprot(mem_axi_cpu_awprot),
		.mem_axi_cpu_wvalid(mem_axi_cpu_wvalid),
		.mem_axi_cpu_wready(mem_axi_cpu_wready),
		.mem_axi_cpu_wdata(mem_axi_cpu_wdata),
		.mem_axi_cpu_wstrb(mem_axi_cpu_wstrb),
		.mem_axi_cpu_bvalid(mem_axi_cpu_bvalid),
		.mem_axi_cpu_bready(mem_axi_cpu_bready),
		.mem_axi_cpu_arvalid(mem_axi_cpu_arvalid),
		.mem_axi_cpu_arready(mem_axi_cpu_arready),
		.mem_axi_cpu_araddr(mem_axi_cpu_araddr),
		.mem_axi_cpu_arprot(mem_axi_cpu_arprot),
		.mem_axi_cpu_rvalid(mem_axi_cpu_rvalid),
		.mem_axi_cpu_rready(mem_axi_cpu_rready),
		.mem_axi_cpu_rdata(mem_axi_cpu_rdata),
		.mem_axi_ram_awvalid(mem_axi_ram_awvalid),
		.mem_axi_ram_awready(mem_axi_ram_awready),
		.mem_axi_ram_awaddr(mem_axi_ram_awaddr),
		.mem_axi_ram_awprot(mem_axi_ram_awprot),
		.mem_axi_ram_wvalid(mem_axi_ram_wvalid),
		.mem_axi_ram_wready(mem_axi_ram_wready),
		.mem_axi_ram_wdata(mem_axi_ram_wdata),
		.mem_axi_ram_wstrb(mem_axi_ram_wstrb),
		.mem_axi_ram_bvalid(mem_axi_ram_bvalid),
		.mem_axi_ram_bready(mem_axi_ram_bready),
		.mem_axi_ram_arvalid(mem_axi_ram_arvalid),
		.mem_axi_ram_arready(mem_axi_ram_arready),
		.mem_axi_ram_araddr(mem_axi_ram_araddr),
		.mem_axi_ram_arprot(mem_axi_ram_arprot),
		.mem_axi_ram_rvalid(mem_axi_ram_rvalid),
		.mem_axi_ram_rready(mem_axi_ram_rready),
		.mem_axi_ram_rdata(mem_axi_ram_rdata),
		.mem_axi_peri_awvalid(mem_axi_peri_awvalid),
		.mem_axi_peri_awready(mem_axi_peri_awready),
		.mem_axi_peri_awaddr(mem_axi_peri_awaddr),
		.mem_axi_peri_awprot(mem_axi_peri_awprot),
		.mem_axi_peri_wvalid(mem_axi_peri_wvalid),
		.mem_axi_peri_wready(mem_axi_peri_wready),
		.mem_axi_peri_wdata(mem_axi_peri_wdata),
		.mem_axi_peri_wstrb(mem_axi_peri_wstrb),
		.mem_axi_peri_bvalid(mem_axi_peri_bvalid),
		.mem_axi_peri_bready(mem_axi_peri_bready),
		.mem_axi_peri_arvalid(mem_axi_peri_arvalid),
		.mem_axi_peri_arready(mem_axi_peri_arready),
		.mem_axi_peri_araddr(mem_axi_peri_araddr),
		.mem_axi_peri_arprot(mem_axi_peri_arprot),
		.mem_axi_peri_rvalid(mem_axi_peri_rvalid),
		.mem_axi_peri_rready(mem_axi_peri_rready),
		.mem_axi_peri_rdata(mem_axi_peri_rdata)
	);

	/*spimemio spimemio (
		.clk    (clk),
		.resetn (resetn),
		.valid  (mem_valid && mem_addr >= 4*MEM_WORDS && mem_addr < 32'h 0200_0000),
		.ready  (spimem_ready),
		.addr   (mem_addr[23:0]),
		.rdata  (spimem_axi_rdata),

		.flash_csb    (flash_csb   ),
		.flash_clk    (flash_clk   ),

		.flash_io0_oe (flash_io0_oe),
		.flash_io1_oe (flash_io1_oe),
		.flash_io2_oe (flash_io2_oe),
		.flash_io3_oe (flash_io3_oe),

		.flash_io0_do (flash_io0_do),
		.flash_io1_do (flash_io1_do),
		.flash_io2_do (flash_io2_do),
		.flash_io3_do (flash_io3_do),

		.flash_io0_di (flash_io0_di),
		.flash_io1_di (flash_io1_di),
		.flash_io2_di (flash_io2_di),
		.flash_io3_di (flash_io3_di),

		.cfgreg_we(spimemio_cfgreg_sel ? mem_wstrb : 4'b 0000),
		.cfgreg_di(mem_axi_wdata),
		.cfgreg_do(spimemio_cfgreg_do)
	);

	simpleuart simpleuart (
		.clk         (clk         ),
		.resetn      (resetn      ),

		.ser_tx      (ser_tx      ),
		.ser_rx      (ser_rx      ),

		.reg_div_we  (simpleuart_reg_div_sel ? mem_wstrb : 4'b 0000),
		.reg_div_di  (mem_axi_wdata),
		.reg_div_do  (simpleuart_reg_div_do),

		.reg_dat_we  (simpleuart_reg_dat_sel ? mem_wstrb[0] : 1'b 0),
		.reg_dat_re  (simpleuart_reg_dat_sel && !mem_wstrb),
		.reg_dat_di  (mem_axi_wdata),
		.reg_dat_do  (simpleuart_reg_dat_do),
		.reg_dat_wait(simpleuart_reg_dat_wait)
	);*/
	/* 
	always @(posedge clk)
		ram_ready <= mem_valid && !mem_ready && mem_addr < 4*MEM_WORDS;
	*/
	picosoc_mem #(
		.WORDS(MEM_WORDS)
	) picosoc_mem_instance (
		.clk(clk),
		.resetn(resetn),
		.mem_axi_ram_awvalid(mem_axi_ram_awvalid),
		.mem_axi_ram_awready(mem_axi_ram_awready),
		.mem_axi_ram_awaddr(mem_axi_ram_awaddr),
		.mem_axi_ram_awprot(mem_axi_ram_awprot),
		.mem_axi_ram_wvalid(mem_axi_ram_wvalid),
		.mem_axi_ram_wready(mem_axi_ram_wready),
		.mem_axi_ram_wdata(mem_axi_ram_wdata),
		.mem_axi_ram_wstrb(mem_axi_ram_wstrb),
		.mem_axi_ram_bvalid(mem_axi_ram_bvalid),
		.mem_axi_ram_bready(mem_axi_ram_bready),
		.mem_axi_ram_arvalid(mem_axi_ram_arvalid),
		.mem_axi_ram_arready(mem_axi_ram_arready),
		.mem_axi_ram_araddr(mem_axi_ram_araddr),
		.mem_axi_ram_arprot(mem_axi_ram_arprot),
		.mem_axi_ram_rvalid(mem_axi_ram_rvalid),
		.mem_axi_ram_rready(mem_axi_ram_rready),
		.mem_axi_ram_rdata(mem_axi_ram_rdata)
	);

    axi_top peri_instance (
        .clk(clk),
		.rst(resetn),
		.s_axi_araddr(mem_axi_peri_araddr),
		.s_axi_arvalid(mem_axi_peri_arvalid),
		.s_axi_arready(mem_axi_peri_arready),
		.s_axi_rdata(mem_axi_peri_rdata),
		.s_axi_rvalid(mem_axi_peri_rvalid),
		.s_axi_rresp(mem_axi_peri_rresp),
		.s_axi_rready(mem_axi_peri_rready),
		.s_axi_awaddr(mem_axi_peri_awaddr),
		.s_axi_awready(mem_axi_peri_awready),
		.s_axi_awvalid(mem_axi_peri_awvalid),
		.s_axi_wdata(mem_axi_peri_wdata),
		.s_axi_wvalid(mem_axi_peri_wvalid),
		.s_axi_wready(mem_axi_peri_wready),
		.s_axi_bresp(mem_axi_peri_bresp),
		.s_axi_bvalid(mem_axi_peri_bvalid),
		.s_axi_bready(mem_axi_peri_bready),
		.tx_o(ser_tx),
		.rx_i(ser_rx)
	);
    
	/*picosoc_mem #(
	) dummy_peripheral_mem (
		.clk(clk),
		.resetn(resetn),
		.mem_axi_ram_awvalid(mem_axi_peri_awvalid),
		.mem_axi_ram_awready(mem_axi_peri_awready),
		.mem_axi_ram_awaddr(mem_axi_peri_awaddr),
		.mem_axi_ram_awprot(mem_axi_peri_awprot),
		.mem_axi_ram_wvalid(mem_axi_peri_wvalid),
		.mem_axi_ram_wready(mem_axi_peri_wready),
		.mem_axi_ram_wdata(mem_axi_peri_wdata),
		.mem_axi_ram_wstrb(mem_axi_peri_wstrb),
		.mem_axi_ram_bvalid(mem_axi_peri_bvalid),
		.mem_axi_ram_bready(mem_axi_peri_bready),
		.mem_axi_ram_arvalid(mem_axi_peri_arvalid),
		.mem_axi_ram_arready(mem_axi_peri_arready),
		.mem_axi_ram_araddr(mem_axi_peri_araddr),
		.mem_axi_ram_arprot(mem_axi_peri_arprot),
		.mem_axi_ram_rvalid(mem_axi_peri_rvalid),
		.mem_axi_ram_rready(mem_axi_peri_rready),
		.mem_axi_ram_rdata(mem_axi_peri_rdata)
	);*/
endmodule

// Implementation note:
// Replace the following two modules with wrappers for your SRAM cells.

module picosoc_regs (
	input clk, wen,
	input [5:0] waddr,
	input [5:0] raddr1,
	input [5:0] raddr2,
	input [31:0] wdata,
	output [31:0] rdata1,
	output [31:0] rdata2
);
	reg [31:0] regs [0:31];

	always @(posedge clk)
		if (wen) regs[waddr[4:0]] <= wdata;

	assign rdata1 = regs[raddr1[4:0]];
	assign rdata2 = regs[raddr2[4:0]];
endmodule

module picosoc_mem #(
	parameter integer WORDS = 256
) (
	input clk,
	input resetn,
	input mem_axi_ram_awvalid,
	output reg mem_axi_ram_awready,
	input [31 : 0] mem_axi_ram_awaddr,
	input [2 : 0] mem_axi_ram_awprot,
	input mem_axi_ram_wvalid,
	output reg mem_axi_ram_wready,
	input [31 : 0] mem_axi_ram_wdata,
	input [3 : 0] mem_axi_ram_wstrb,
	output reg mem_axi_ram_bvalid,
	input mem_axi_ram_bready,
	input mem_axi_ram_arvalid,
	output reg mem_axi_ram_arready,
	input [31 : 0] mem_axi_ram_araddr,
	input [2 : 0] mem_axi_ram_arprot,
	output reg mem_axi_ram_rvalid,
	input mem_axi_ram_rready,
	output reg [31 : 0] mem_axi_ram_rdata
);
	reg [31:0] mem [0:WORDS-1] /*synthesis syn_ramstyle="block_ram"*/;
	initial $readmemh("/home/lukas/digital/uart/cpu/picorv32/picosoc/uart_firmware/firmware.hex", mem);
	parameter DECODE = 0, LOAD = 1, RESP = 2;
	reg [1 : 0] axi_write_state;
    initial axi_write_state = DECODE;
	reg axi_read_state;
	reg [29 : 0] addr;
	always @(posedge clk) begin


		/*******************************/
		/*  AXILite Write			   */
		/*******************************/

		case (axi_write_state)
			DECODE :
				if(mem_axi_ram_awvalid) begin
					if(mem_axi_ram_awready)	begin
						//Both valid and ready active, can transact
						mem_axi_ram_wready <= 1;
						addr <= mem_axi_ram_awaddr[31 : 2];
						axi_write_state <= LOAD;
						//Deassert AW Ready to prevent unwanted handshake
						mem_axi_ram_awready <= 0;
					end else begin
						//Assert AW Ready to enable handshake
						mem_axi_ram_awready <= 1;
					end
				end
			LOAD :
				if(mem_axi_ram_wvalid) begin
					if(mem_axi_ram_wready) begin
						if(mem_axi_ram_wstrb[0]) mem[addr][7 : 0] <= mem_axi_ram_wdata[7 : 0];
						if(mem_axi_ram_wstrb[1]) mem[addr][15 : 8] <= mem_axi_ram_wdata[15 : 8];
						if(mem_axi_ram_wstrb[2]) mem[addr][23 : 16] <= mem_axi_ram_wdata[23 : 16];
						if(mem_axi_ram_wstrb[3]) mem[addr][31 : 24] <= mem_axi_ram_wdata[31 : 24]; 
						mem_axi_ram_bvalid <= 1;
						axi_write_state <= RESP;
						//Deassert W Ready to prevent unwanted handshake
						mem_axi_ram_wready <= 0;
					end else begin
						//Assert W Ready to enable handshake
						mem_axi_ram_wready <= 1;
					end
				end
			default :
				//RESP
				if(mem_axi_ram_bready) begin
					if(mem_axi_ram_bvalid) begin
						axi_write_state <= DECODE;
						mem_axi_ram_bvalid <= 0;
					end else begin
						mem_axi_ram_bvalid <= 1;
					end
				end
		endcase
		

		/*******************************/
		/*  AXILite Read			   */
		/*******************************/

		
		case (axi_read_state)
			DECODE :
				if(mem_axi_ram_arvalid) begin
					if(mem_axi_ram_arready)	begin
						//Both valid and ready active, can transact
						mem_axi_ram_rvalid <= 1;
						axi_read_state <= LOAD; 
						//Disable AR Ready to prevent unwanted handshake
						mem_axi_ram_arready <= 0;
					end else begin
						mem_axi_ram_arready <= 1;
					end
				end
			default :
				//LOAD
				if(mem_axi_ram_rvalid) begin
					if(mem_axi_ram_rready) begin
						//Both valid and ready active, can transact
						axi_read_state <= DECODE;
						//Disable R Valid to prevent unwanted handshake
						mem_axi_ram_rvalid <= 0;
					end
				end else begin
					mem_axi_ram_rvalid <= 1;
				end
		endcase

		mem_axi_ram_rdata <= mem[mem_axi_ram_araddr[31 : 2]];

        if(~resetn) begin
            axi_read_state <= DECODE;
            axi_write_state <= DECODE;
            mem_axi_ram_awready <= 0;
            mem_axi_ram_arready <= 0;
            mem_axi_ram_rvalid <= 0;
            mem_axi_ram_wready <= 0;
            //mem_axi_ram_rdata <= 0;
            mem_axi_ram_bvalid <= 0;
            /*for(integer i = 0; i < WORDS; i++) begin
                mem[i] = '0;
            end*/
        end
	end
	/*assign debugger = mem[0];
	assign debugger1 = mem[1];
	assign debugger2 = mem[2];
	assign debugger3 = mem[3];*/
endmodule


module picosoc_dec #(
    parameter integer mem_words = 256,
    parameter integer stackaddr = 4*mem_words,
	parameter integer addr_num = 4
) (
		input clk,
		//TO CPU
		input mem_axi_cpu_awvalid,
		output reg mem_axi_cpu_awready,
		input [31 : 0] mem_axi_cpu_awaddr,
		input [2 : 0] mem_axi_cpu_awprot,
		input mem_axi_cpu_wvalid,
		output reg mem_axi_cpu_wready,
		input [31 : 0] mem_axi_cpu_wdata,
		input [3 : 0] mem_axi_cpu_wstrb,
		output reg mem_axi_cpu_bvalid,
		input mem_axi_cpu_bready,
		input mem_axi_cpu_arvalid,
		output reg mem_axi_cpu_arready,
		input [31 : 0]mem_axi_cpu_araddr,
		input [2 : 0] mem_axi_cpu_arprot,
		output reg mem_axi_cpu_rvalid,
		input mem_axi_cpu_rready,
		output reg [31 : 0] mem_axi_cpu_rdata,
		//TO RAM
		output reg mem_axi_ram_awvalid,
		input mem_axi_ram_awready,
		output reg [31 : 0] mem_axi_ram_awaddr,
		output reg [2 : 0] mem_axi_ram_awprot,
		output reg mem_axi_ram_wvalid,
		input mem_axi_ram_wready,
		output reg [31 : 0] mem_axi_ram_wdata,
		output reg [3 : 0] mem_axi_ram_wstrb,
		input mem_axi_ram_bvalid,
		output reg mem_axi_ram_bready,
		output reg mem_axi_ram_arvalid,
		input mem_axi_ram_arready,
		output reg [31 : 0] mem_axi_ram_araddr,
		output reg [2 : 0] mem_axi_ram_arprot,
		input mem_axi_ram_rvalid,
		output reg mem_axi_ram_rready,
		input [31 : 0] mem_axi_ram_rdata,
		//TO PERIPH
		output reg mem_axi_peri_awvalid,
		input mem_axi_peri_awready,
		output reg [31 : 0] mem_axi_peri_awaddr,
		output reg [2 : 0] mem_axi_peri_awprot,
		output reg mem_axi_peri_wvalid,
		input mem_axi_peri_wready,
		output reg [31 : 0] mem_axi_peri_wdata,
		output reg [3 : 0] mem_axi_peri_wstrb,
		input mem_axi_peri_bvalid,
		output reg mem_axi_peri_bready,
		output reg mem_axi_peri_arvalid,
		input mem_axi_peri_arready,
		output reg [31 : 0] mem_axi_peri_araddr,
		output reg [2 : 0] mem_axi_peri_arprot,
		input mem_axi_peri_rvalid,
		output reg mem_axi_peri_rready,
		input [31 : 0] mem_axi_peri_rdata
);
	reg lock_peri, lock_ram;
	wire lock;
	initial lock_peri = 0;
	initial lock_ram = 0;
	//routing for AXILite Read Bus
	always @(posedge clk) begin
		if(lock == 0) begin
			//No lock applied, can take control
			if(mem_axi_cpu_arvalid) begin
				//write or read initiated
				if(mem_axi_cpu_araddr > stackaddr - 1) begin
					//route to peripherial and acquire lock
					lock_peri <= 1;
				end
				else if(mem_axi_cpu_araddr < stackaddr) begin
                    //route to RAM and acquire lock
                    lock_ram <= 1;
				end
			end else if(mem_axi_cpu_awvalid) begin
				//write or read initiated
				if(mem_axi_cpu_awaddr > stackaddr - 1) begin
					//route to peripherial and acquire lock
					lock_peri <= 1;
				end
				else if(mem_axi_cpu_awaddr < stackaddr) begin
                    //route to RAM and acquire lock
                    lock_ram <= 1;
				end
			end
		end else begin
            if(lock_ram) begin
                if((mem_axi_ram_bvalid & mem_axi_cpu_bready) | (mem_axi_ram_rvalid & mem_axi_cpu_rready)) begin
                    //final clock cycle of transaction, can return lock
                    lock_ram <= 0;
                end
            end else if(lock_peri) begin
                if((mem_axi_peri_bvalid & mem_axi_cpu_bready) | (mem_axi_peri_rvalid & mem_axi_cpu_rready)) begin
                    //final clock cycle of transaction, can return lock
                    lock_peri <= 0;
                end
            end
		end
	end
    always @(*) begin
        /******************/
        /* DEFAULT VALUES */
        /******************/
        //AR Bus
        mem_axi_peri_araddr = 0;
        mem_axi_peri_arvalid = 0;
        mem_axi_cpu_arready = 0;
        mem_axi_peri_arprot = 0;
        //R Bus
        mem_axi_cpu_rvalid = 0;
        mem_axi_cpu_rdata = 0;
        mem_axi_peri_rready = 0;
        //AW Bus
        mem_axi_peri_awaddr = 0;
        mem_axi_peri_awvalid = 0;
        mem_axi_cpu_awready = 0;
        mem_axi_peri_awprot = 0;
        //W Bus
        mem_axi_cpu_wready = 0;
        mem_axi_peri_wdata = 0;
        mem_axi_peri_wvalid = 0;
        mem_axi_peri_wstrb = 0;
        //B Bus
        mem_axi_peri_bready = 0;
        mem_axi_cpu_bvalid = 0;	
        //AR Bus
        mem_axi_ram_araddr = 0;
        mem_axi_ram_arvalid = 0;
        mem_axi_cpu_arready = 0;
        mem_axi_ram_arprot = 0;
        mem_axi_ram_arprot = 0;
        //R Bus
        mem_axi_cpu_rvalid = 0;
        mem_axi_cpu_rdata = 0;
        mem_axi_ram_rready = 0;
        //AW Bus
        mem_axi_ram_awaddr = 0;
        mem_axi_ram_awvalid = 0;
        mem_axi_cpu_awready = 0;
        mem_axi_ram_awprot = 0;
        //W Bus
        mem_axi_cpu_wready = 0;
        mem_axi_ram_wdata = 0;
        mem_axi_ram_wvalid = 0;
        mem_axi_ram_wstrb = 0;
        //B Bus
        mem_axi_ram_bready = 0;
        mem_axi_cpu_bvalid = 0;
        if(lock_peri) begin
            //lock acquired by peripheral
            //AR Bus
            mem_axi_peri_araddr = mem_axi_cpu_araddr - stackaddr;
            mem_axi_peri_arvalid = mem_axi_cpu_arvalid;
            mem_axi_cpu_arready = mem_axi_peri_arready;
            mem_axi_peri_arprot = mem_axi_cpu_arprot;
            //R Bus
            mem_axi_cpu_rvalid = mem_axi_peri_rvalid;
            mem_axi_cpu_rdata = mem_axi_peri_rdata;
            mem_axi_peri_rready = mem_axi_cpu_rready;
            //AW Bus
            mem_axi_peri_awaddr = mem_axi_cpu_awaddr - stackaddr;
            mem_axi_peri_awvalid = mem_axi_cpu_awvalid;
            mem_axi_cpu_awready = mem_axi_peri_awready;
            mem_axi_peri_awprot = mem_axi_cpu_awprot;
            //W Bus
            mem_axi_cpu_wready = mem_axi_peri_wready;
            mem_axi_peri_wdata = mem_axi_cpu_wdata;
            mem_axi_peri_wvalid = mem_axi_cpu_wvalid;
            mem_axi_peri_wstrb = mem_axi_cpu_wstrb;
            //B Bus
            mem_axi_peri_bready = mem_axi_cpu_bready;
            mem_axi_cpu_bvalid = mem_axi_peri_bvalid;	
        end else if(lock_ram) begin
            //lock acquired by ram
            //AR Bus
            mem_axi_ram_araddr = mem_axi_cpu_araddr;
            mem_axi_ram_arvalid = mem_axi_cpu_arvalid;
            mem_axi_cpu_arready = mem_axi_ram_arready;
            mem_axi_ram_arprot = mem_axi_cpu_arprot;
            //R Bus
            mem_axi_cpu_rvalid = mem_axi_ram_rvalid;
            mem_axi_cpu_rdata = mem_axi_ram_rdata;
            mem_axi_ram_rready = mem_axi_cpu_rready;
            //AW Bus
            mem_axi_ram_awaddr = mem_axi_cpu_awaddr;
            mem_axi_ram_awvalid = mem_axi_cpu_awvalid;
            mem_axi_cpu_awready = mem_axi_ram_awready;
            mem_axi_ram_awprot = mem_axi_cpu_awprot;
            //W Bus
            mem_axi_cpu_wready = mem_axi_ram_wready;
            mem_axi_ram_wdata = mem_axi_cpu_wdata;
            mem_axi_ram_wvalid = mem_axi_cpu_wvalid;
            mem_axi_ram_wstrb = mem_axi_cpu_wstrb;
            //B Bus
            mem_axi_ram_bready = mem_axi_cpu_bready;
            mem_axi_cpu_bvalid = mem_axi_ram_bvalid;
        end
    end
	assign lock = lock_ram | lock_peri;
endmodule