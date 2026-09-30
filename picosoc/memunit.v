module memunit(
    input clk,
    input rst,
    input din[31 : 0],
    output dout[31 : 0],
    input xadr[8:0],
    input yadr[5:0],
    input xe,
    input ye,
    input se,
    input prog,
    input erase,
    input nvstr
);
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


endmodule

module memcontrol #(
    parameter integer CLK_FREQ = 27_000_000
) (
    input clk,
    input resetn,
    //AW BUS
	input mem_axi_ram_awvalid,
	output reg mem_axi_ram_awready,
	input [31 : 0] mem_axi_ram_awaddr,
	input [2 : 0] mem_axi_ram_awprot,
	//W BUS
    input mem_axi_ram_wvalid,
	output reg mem_axi_ram_wready,
	input [31 : 0] mem_axi_ram_wdata,
	input [3 : 0] mem_axi_ram_wstrb,
	//B BUS
    output reg mem_axi_ram_bvalid,
	input mem_axi_ram_bready,
	//AR BUS
    input mem_axi_ram_arvalid,
	output reg mem_axi_ram_arready,
	input [31 : 0] mem_axi_ram_araddr,
	input [2 : 0] mem_axi_ram_arprot,
	//R BUS
    output reg mem_axi_ram_rvalid,
	input mem_axi_ram_rready,
	output reg [31 : 0] mem_axi_ram_rdata,
    //MEM Interface
    output [31 : 0] din,
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
    reg [bits(2 + (CLK_FREQ * (5 + 10 + 12 + 6000 + 5)) / 1_000_000) : 0] counter_write;
    reg [31 : 0] counter_read; //TODO: REPLACE PLACEHOLDER WIDTH WITH ACTUAL REQUIREMENT!
    /**************************/
    /*      AXILite Write     */
    /**************************/ 
    always @(posedge(clk)) begin
        if(~resetn) begin
            //TODO: FINISH RESET CONDITIONS
        end else begin
            /* DEFAULT VALUES */
            //mem_axi_ram_
            casex(state_write)
                DECODE: begin
                    if (mem_axi_ram_awready) begin
                        if(mem_axi_ram_awvalid) begin
                            // Both valid and ready active, can transact
                            addr_write <= mem_axi_ram_awaddr[31 : 2];
                            state_write <= LOAD;  
                            mem_axi_ram_awready <= 0;     
                        end 
                    end else begin
                        //Module not ready, cannot transact
                        mem_axi_ram_awready <= 1;
                    end
                end
                LOAD: begin
                    if(mem_axi_ram_wready) begin
                        if(mem_axi_ram_wvalid) begin
                            yadr <= addr_write[5 : 0];
                            xadr <= {addr_write[13 : 9], addr_write[8 : 6]};
                            din <= mem_axi_ram_wdata;
                            mem_axi_ram_wready <= 0;
                        end
                    end else begin
                        mem_axi_ram_wready <= 1;
                    end
                end
                RESP: begin
                    counter_write <= counter_write + 1; // Default value
                    case(counter_write)
                        0: begin
                            se <= 0;
                            erase <= 0;
                            ye <= 0;
                            xe <= 1;
                        end
                        1:
                            // Await Twpr (20 ns)
                            prog <= 1;
                        (1 + (CLK_FREQ * 5) / 1_000_000):
                            // Await Tnvs (5 us)
                            nvstr <= 1;
                        (1 + (CLK_FREQ * (5 + 10)) / 1_000_000):
                            // Await Tpgs (10 us)
                            ye <= 1;
                        (1 + (CLK_FREQ * (5 + 10 + 12)) / 1_000_000):
                            // Await Tprog (8-12 us, 12 chosen)
                            ye <= 0;
                        (1 + (CLK_FREQ * (5 + 10 + 12 + 6000)) / 1_000_000):
                            //Await Thv (6 ms) and Tpgh (20 ns)
                            prog <= 0;
                        (2 + (CLK_FREQ * (5 + 10 + 12 + 6000 + 5)) / 1_000_000): begin
                            // Await Tnvh (5 us) and Twhd (20 ns)
                            nvstr <= 0;
                            state_write <= RESP;
                            xe <= 0;
                            prog <= 0;
                            counter_write <= counter_write;
                            if(mem_axi_ram_bvalid) begin
                                if(mem_axi_ram_bready) begin
                                    mem_axi_ram_bvalid <= 0;
                                    counter_write <= 0;
                                    state_write <= DECODE;
                                end
                            end else begin
                                mem_axi_ram_bvalid <= 1;
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
        case(state_read)
            DECODE: begin
                if(mem_axi_ram_arready) begin
                    if(mem_axi_ram_arvalid) begin
                        addr_read <= mem_axi_ram_araddr[31 : 2];
                        state_read <= LOAD;
                        mem_axi_ram_arready <= 0;
                    end
                end else begin
                    mem_axi_ram_arready <= 1;
                end
            end
            LOAD: begin
                /* Default value */
                counter_read <= counter_read + 1;
                case (counter_read)
                    0 : begin
                        xe <= 1;
                        ye <= 1;
                    end
                    1 : begin
                        // Await Tas (1 ns)
                        se <= 1;
                    end
                    2 : begin
                        // Await Tpws (5 ns) and Tah (25 ns)
                        se <= 0;
                        ye <= 0;
                        xe <= 0;
                    end
                    3 : begin
                        // Await Tdh (0.5 ns)
                        mem_axi_ram_rdata <= dout;
                    end
                    4 : begin
                        // Await Tnws (2 ns)
                        if(mem_axi_ram_rvalid) begin
                            if(mem_axi_ram_rready) begin
                                mem_axi_ram_rvalid <= 0;
                            end
                        end else begin
                            mem_axi_ram_rvalid <= 1;
                        end
                    end
                endcase
            end
        endcase
    end

    function integer bits(input integer val);
        begin
            for(bits = 0; val > 0; val = val / 2)
                bits++;
        end
    endfunction
    
endmodule