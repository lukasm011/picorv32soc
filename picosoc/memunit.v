module memunit(
    input clk,
    input resetn,
    //AW BUS
	input mem_axi_flash_awvalid,
	output mem_axi_flash_awready,
	input [31 : 0] mem_axi_flash_awaddr,
	input [2 : 0] mem_axi_flash_awprot,
	//W BUS
    input mem_axi_flash_wvalid,
	output mem_axi_flash_wready,
	input [31 : 0] mem_axi_flash_wdata,
	input [3 : 0] mem_axi_flash_wstrb,
	//B BUS
    output mem_axi_flash_bvalid,
	input mem_axi_flash_bready,
	//AR BUS
    input mem_axi_flash_arvalid,
	output mem_axi_flash_arready,
	input [31 : 0] mem_axi_flash_araddr,
	input [2 : 0] mem_axi_flash_arprot,
	//R BUS
    output mem_axi_flash_rvalid,
	input mem_axi_flash_rready,
	output [31 : 0] mem_axi_flash_rdata
);
    wire [8 : 0] xadr;
    wire [5 : 0] yadr;
    wire xe;
    wire ye;
    wire se;
    wire erase;
    wire prog;
    wire nvstr;
    wire [31 : 0] din;
    wire [31 : 0] dout;
    FLASH608K flash608k_inst(
        .XADR(xadr[8:0]),
        .YADR(yadr[5:0]),
        .XE(xe),
        .YE(ye),
        .SE(se),
        .ERASE(erase),
        .PROG(prog),
        .NVSTR(nvstr),
        .DIN(din[31:0]),
        .DOUT(dout[31:0])
    );
    memcontrol #(
        .CLK_PER_US(27)
    ) memcontrol_instance (
        .clk(clk),
        .resetn(resetn),
        .mem_axi_flash_awvalid(mem_axi_flash_awvalid),
        .mem_axi_flash_awready(mem_axi_flash_awready),
        .mem_axi_flash_awaddr(mem_axi_flash_awaddr),
        .mem_axi_flash_awprot(mem_axi_flash_awprot),
        .mem_axi_flash_wvalid(mem_axi_flash_wvalid),
        .mem_axi_flash_wready(mem_axi_flash_wready),
        .mem_axi_flash_wdata(mem_axi_flash_wdata),
        .mem_axi_flash_wstrb(mem_axi_flash_wstrb),
        .mem_axi_flash_bvalid(mem_axi_flash_bvalid),
        .mem_axi_flash_bready(mem_axi_flash_bready),
        .mem_axi_flash_arvalid(mem_axi_flash_arvalid),
        .mem_axi_flash_arready(mem_axi_flash_arready),
        .mem_axi_flash_araddr(mem_axi_flash_araddr),
        .mem_axi_flash_arprot(mem_axi_flash_arprot),
        .mem_axi_flash_rvalid(mem_axi_flash_rvalid),
        .mem_axi_flash_rready(mem_axi_flash_rready),
        .mem_axi_flash_rdata(mem_axi_flash_rdata),
        .din(din),
        .dout(dout),
        .xadr(xadr),
        .yadr(yadr),
        .xe(xe),
        .ye(ye),
        .se(se),
        .prog(prog),
        .erase(erase),
        .nvstr(nvstr)
    );

endmodule

module memcontrol #(
    parameter integer CLK_PER_US = 27
) (
    input clk,
    input resetn,
    //AW BUS
	input mem_axi_flash_awvalid,
	output reg mem_axi_flash_awready,
	input [31 : 0] mem_axi_flash_awaddr,
	input [2 : 0] mem_axi_flash_awprot,
	//W BUS
    input mem_axi_flash_wvalid,
	output reg mem_axi_flash_wready,
	input [31 : 0] mem_axi_flash_wdata,
	input [3 : 0] mem_axi_flash_wstrb,
	//B BUS
    output reg mem_axi_flash_bvalid,
	input mem_axi_flash_bready,
	//AR BUS
    input mem_axi_flash_arvalid,
	output reg mem_axi_flash_arready,
	input [31 : 0] mem_axi_flash_araddr,
	input [2 : 0] mem_axi_flash_arprot,
	//R BUS
    output reg mem_axi_flash_rvalid,
	input mem_axi_flash_rready,
	output reg [31 : 0] mem_axi_flash_rdata,
    //MEM Interface
    output reg [31 : 0] din,
    input [31 : 0] dout,
    output [8:0] xadr,
    output [5:0] yadr,
    output xe,
    output ye,
    output se,
    output prog,
    output erase,
    output nvstr
);
    parameter DECODE = 0, LOAD = 1, RESP = 2;
    reg [1 : 0] state_write;
    reg state_read;
    reg [29 : 0] addr_write;
    reg [29 : 0] addr_read;
    reg [bits(2 + (CLK_PER_US * (5 + 10 + 12 + 6000 + 5))) - 1 : 0] counter_write;
    reg [31 : 0] counter_read; //TODO: REPLACE PLACEHOLDER WIDTH WITH ACTUAL REQUIREMENT!
    reg [8 : 0] xadr_write;
    reg [5 : 0] yadr_write;
    reg [8 : 0] xadr_read;
    reg [5 : 0] yadr_read;
    reg xe_write;
    reg ye_write;
    reg se_write;
    reg prog_write;
    reg erase_write;
    reg nvstr_write;
    reg xe_read;
    reg ye_read;
    reg se_read;
    reg prog_read;
    reg erase_read;
    reg nvstr_read;
    reg read_lock;
    reg write_lock;
    wire lock;
    /**************************/
    /*      AXILite Write     */
    /**************************/ 
    always @(posedge(clk)) begin
        if(~resetn) begin
            //TODO: FINISH RESET CONDITIONS
            write_lock <= 0;
            state_write <= DECODE;
            mem_axi_flash_awready <= 0;
            mem_axi_flash_wready <= 0;
            mem_axi_flash_bvalid <= 0;
            xadr_write <= 0;
            yadr_write <= 0;
            din <= 0;
            xe_write <= 0;
            ye_write <= 1;
            se_write <= 1;
            nvstr_write <= 0;
            prog_write <= 0;
            erase_write <= 1;
            counter_write <= 0;
        end else begin
            /* DEFAULT VALUES */
            //mem_axi_flash_
            casex(state_write)
                DECODE: begin
                    if(~lock) begin
                        if (mem_axi_flash_awready) begin
                            if(mem_axi_flash_awvalid && ~lock) begin
                                // Both valid and ready active, can transact
                                write_lock <= 1;
                                addr_write <= mem_axi_flash_awaddr[31 : 2];
                                state_write <= LOAD;  
                                mem_axi_flash_awready <= 0;     
                            end 
                        end else begin
                            //Module not ready, cannot transact
                            mem_axi_flash_awready <= 1;
                        end
                    end else begin
                        mem_axi_flash_awready <= 0;
                    end
                end
                LOAD: begin
                    if(mem_axi_flash_wready) begin
                        if(mem_axi_flash_wvalid) begin
                            yadr_write <= addr_write[5 : 0];
                            xadr_write <= {addr_write[13 : 9], addr_write[8 : 6]};
                            din <= mem_axi_flash_wdata;
                            mem_axi_flash_wready <= 0;
                            counter_write <= 0;
                            state_write <= RESP;
                        end
                    end else begin
                        mem_axi_flash_wready <= 1;
                    end
                end
                RESP: begin
                    counter_write <= counter_write + 1; // Default value
                    case(counter_write)
                        0: begin
                            se_write <= 0;
                            erase_write <= 0;
                            ye_write <= 0;
                            xe_write <= 1;
                        end
                        1:
                            // Await Twpr (20 ns)
                            prog_write <= 1;
                        (1 + (CLK_PER_US * 5)):
                            // Await Tnvs (5 us)
                            nvstr_write <= 1;
                        (1 + (CLK_PER_US * (5 + 10))):
                            // Await Tpgs (10 us)
                            ye_write <= 1;
                        (1 + (CLK_PER_US * (5 + 10 + 12))):
                            // Await Tprog (8-12 us, 12 chosen)
                            ye_write <= 0;
                        (2 + (CLK_PER_US * (5 + 10 + 12))):
                            // Await Tpgh (20 ns)
                            prog_write <= 0;
                        (3 + (CLK_PER_US * (5 + 10 + 12 + 5))): begin
                            // Await Tnvh (5 us) and Twhd (20 ns)
                            nvstr_write <= 0;
                            se_write <= 1;
                            state_write <= RESP;
                            xe_write <= 0;
                            prog_write <= 0;
                            counter_write <= counter_write;
                            if(mem_axi_flash_bvalid) begin
                                if(mem_axi_flash_bready) begin
                                    write_lock <= 0;
                                    mem_axi_flash_bvalid <= 0;
                                    counter_write <= 0;
                                    state_write <= DECODE;
                                end
                            end else begin
                                mem_axi_flash_bvalid <= 1;
                            end
                        end
                        default: //something goes here
                        begin end
                    endcase
                end
            endcase
        end
    end
    /**************************/
    /*      AXILite Read      */
    /**************************/
    /*IMPORTANT TODO: IS IT NECESSARY TO WAIT FOR ONE EXTRA CLOCK CYCLE DUE TO THE READ TIME(25ns) */
    always @(posedge(clk)) begin
        if(~resetn) begin
            read_lock <= 0;
            addr_read <= 0;
            state_read <= DECODE;
            mem_axi_flash_arready <= 0;
            mem_axi_flash_rvalid <= 0;
            mem_axi_flash_rdata <= 0;
            xe_read <= 0;
            ye_read <= 0;
            se_read <= 0;
            xadr_read <= 0;
            yadr_read <= 0;
            nvstr_read <= 0;
            erase_read <= 0;
            prog_read <= 0;
            counter_read <= 0;
        end else begin
            case(state_read)
                DECODE: begin
                    if(~lock) begin
                        if(mem_axi_flash_arready) begin
                            if(mem_axi_flash_arvalid) begin
                                read_lock <= 1;
                                addr_read <= mem_axi_flash_araddr[31 : 2];
                                state_read <= LOAD;
                                mem_axi_flash_arready <= 0;
                                counter_read <= 0;
                            end
                        end else begin
                            mem_axi_flash_arready <= 1;
                        end
                    end else begin
                        mem_axi_flash_arready <= 0;
                    end
                end
                LOAD: begin
                    /* Default value */
                    counter_read <= counter_read + 1;
                    case (counter_read)
                        0 : begin
                            yadr_read <= addr_read[5 : 0];
                            xadr_read <= {addr_read[13 : 9], addr_read[8 : 6]};
                            xe_read <= 1;
                            ye_read <= 1;
                        end
                        1 : begin
                            // Await Tas (1 ns)
                            se_read <= 1;
                        end
                        2 : begin
                            // Await Tpws (5 ns) and Tah (25 ns)
                            se_read <= 0;
                            ye_read <= 0;
                            xe_read <= 0;
                        end
                        3 : begin
                            // Await Tdh (0.5 ns)
                            mem_axi_flash_rdata <= dout;
                        end
                        4 : begin
                            // Await Tnws (2 ns)
                            counter_read <= counter_read;
                            if(mem_axi_flash_rvalid) begin
                                if(mem_axi_flash_rready) begin
                                    read_lock <= 0;
                                    counter_read <= 0;
                                    mem_axi_flash_rvalid <= 0;
                                    state_read <= DECODE;
                                end
                            end else begin
                                mem_axi_flash_rvalid <= 1;
                            end
                        end
                    endcase
                end
            endcase
        end
    end

    function integer bits(input integer val);
        begin
            for(bits = 0; val > 0; val = val / 2)
                bits = bits + 1;
        end
    endfunction
    
    assign lock = write_lock | read_lock;
    assign xadr = write_lock ? xadr_write : xadr_read;
    assign yadr = write_lock ? yadr_write : yadr_read;
    assign xe = write_lock ? xe_write : xe_read;
    assign ye = write_lock ? ye_write : ye_read;
    assign se = write_lock ? se_write : se_read;
    assign prog = write_lock ? prog_write : prog_read;
    assign erase = write_lock ? erase_write : erase_read;
    assign nvstr = write_lock ? nvstr_write : nvstr_read; 

endmodule