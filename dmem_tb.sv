module dmem_tb;
    logic clk;
    logic WrM, RdM;
    logic [31:0] WriteDataM;
    logic [3:0] AdrM_i;
	
	logic cpu_stall;

    // Bus
    logic [1:0] bus_message_i; 
    logic [1:0] bus_message_o;

	logic seen_i;
	logic seen_o;

    logic bus_response_valid; // if the other cache says abort mem access 
    logic [31:0] bus_data_i;
    logic [3:0] bus_addr_i; // snoop communicate address 
    logic bus_data_valid; // announces to the other core we have the data needed

    // Main memory
    logic mmvalid;
    logic [31:0] mmdata;
    logic [1:0] mmtag;

    logic mem_rden, mem_wren; 

    // Address - data output
    logic [3:0] Addr_rq;
    logic [31:0] data_o;

    logic [112:0] input_cache;

    //tb
    logic [1:0] mesi, tag;


 
    dmem dut(
        clk,
        WrM, RdM, 
        WriteDataM,
        AdrM_i,
        
        cpu_stall,

        // Bus
        bus_message_i, 
        bus_message_o,

        seen_i,
        seen_o,

        bus_response_valid, // if the other cache says abort mem access 
        bus_data_i,
        bus_addr_i, // snoop communicate address 
        bus_data_valid, // announces to the other core we have the data needed

        // Main memory
        mmvalid,
        mmdata,
        mmtag,

        mem_rden, mem_wren, 

        // Address - data output
        Addr_rq,
        data_o,

        mesi,
        tag
    );

// Bus parameters
parameter NA = 2'b00, bus_invalidate = 2'b01, bus_write_miss = 2'b10, bus_read_miss = 2'b11;


localparam CLK_PERIOD = 10;
initial clk = 1'b0;
always #(CLK_PERIOD/2) clk=~clk;

assign {RdM, WrM, WriteDataM, AdrM_i, bus_message_i, seen_i, bus_response_valid, bus_data_i, bus_addr_i, mmvalid, mmdata, mmtag} = input_cache;


	// 	cache[0] = {E, 2'b00, 32'h000d};
	// 	cache[1] = {M, 2'b01, 32'h000a};
	// 	cache[2] = {S, 2'b10, 32'h000d};
	// 	cache[3] = {I, 2'b11, 32'h000a};

initial begin
    #0
        input_cache = 113'b0;
    #(CLK_PERIOD/2) 
        input_cache = { 1'b0, 1'b1, 32'hc, 4'b0100, NA, 1'b0, 1'b0, 32'b0, 4'b0, 1'b0, 32'b0, 2'b00 };
    #(CLK_PERIOD)
        input_cache = { 1'b1, 1'b0, 32'h0, 4'b0100, NA, 1'b0, 1'b0, 32'b0, 4'b0, 1'b0, 32'b0, 2'b00 };
    #(CLK_PERIOD)
        input_cache = { 1'b1, 1'b0, 32'h0, 4'b0101, NA, 1'b0, 1'b0, 32'b0, 4'b0, 1'b0, 32'b0, 2'b00 };
    #3
        input_cache = { 1'b1, 1'b0, 32'h0, 4'b0101, bus_read_miss, 1'b0, 1'b0, 32'b0, 4'b0100, 1'b0, 32'b0, 2'b00};
    #(CLK_PERIOD-3)
        input_cache = 113'b0;
    repeat(8) @(posedge clk);
    $stop;
end

endmodule
