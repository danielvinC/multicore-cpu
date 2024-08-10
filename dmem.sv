module dmem(
    // CPU
    input logic clk,
    input logic WrM, RdM, 
    input logic [31:0] WriteDataM,
    input logic [3:0] AdrM_i,
	
	output logic cpu_stall,

    // Bus
    input logic [1:0] bus_message_i, 
    output logic [1:0] bus_message_o,

	input logic seen_i,
	output logic seen_o,

    input logic bus_response_valid, // if the other cache says abort mem access 
    input logic [31:0] bus_data_i,
    input logic [3:0] bus_addr_i, // snoop communicate address 
    output logic bus_data_valid, // announces to the other core we have the data needed

    // Main memory
    input logic mmvalid,
    input logic [31:0] mmdata,
    input logic [1:0] mmtag,

    output logic mem_rden, mem_wren, 

    // Address - data output
    output logic [3:0] Addr_rq,
    output logic [31:0] data_o,

	//tb
	output logic [1:0] status, tag
	);


    
    // mesis parameters
    parameter I = 2'b00, M = 2'b01, S = 2'b10, E = 2'b11;

    // Bus parameters
    parameter NA = 2'b00, bus_invalidate = 2'b01, bus_write_miss = 2'b10, bus_read_miss = 2'b11;

    // Request parameters
    parameter write_hit = 2'b00, read_hit = 2'b01, write_miss = 2'b10, read_miss = 2'b11; 

	// Cache Line Configuration Scheme:
    // |coherency mesi ~2bits|tag ~2bits|data ~32bits|
    //  35                  34 33      32 31         0
    logic [35:0] cache [3:0];

	initial begin
		cache[0] = {E, 2'b00, 32'h000d};
		cache[1] = {M, 2'b01, 32'h000a};
		cache[2] = {S, 2'b10, 32'h000d};
		cache[3] = {I, 2'b11, 32'h000a};
	end

    // Address register
    logic [3:0] AdrM;
    // Proc request address
    logic [1:0] index_proc, tag_proc;
	// Snoop request address
	logic [1:0] index_snoop, tag_snoop;
	// tag register
	logic [1:0] tag_reg; 
	// Proc operations
    logic [2:0] read_write;
    // Action & snoop signals
    logic [1:0] Updated_MESI_state_proc, Updated_MESI_state_snoop, Current_MESI_state_proc, Current_MESI_state_snoop, message_i;
    logic hit_proc, hit_snoop, active;
    logic mem_rden_proc, mem_wren_snoop;
    logic bus_response_valid_q, shared, prior;
    // CPU request signals
    logic we_n, we_q;
    logic [1:0] wrAdr_q;
    logic [31:0] wd_q;



	assign active = RdM || WrM;
	assign cpu_stall = read_write == read_miss;

    // Decomposing the CPU address input into index and tag
    assign tag_reg = cache[index_proc][33:32]; 

	assign status = cache[AdrM[1:0]][35:34];
	assign tag 	  = cache[AdrM[1:0]][33:32];
	
	always_comb begin
		//default
		read_write = 3'b111;
		bus_message_o = NA;
		{tag_proc, index_proc} = 4'b0;
		hit_proc = 1'b0;
		Current_MESI_state_proc = cache[index_proc][35:34];
		if ( active ) begin 
			prior = 1'b1;
			{tag_proc, index_proc} = AdrM;
			hit_proc = (cache[index_proc][35:34] != I) && (tag_proc == tag_reg);
			if (hit_proc) begin 
				if (WrM) begin
					read_write = {1'b0, write_hit};
					if (Current_MESI_state_proc == S) 
						bus_message_o = bus_invalidate;
				end else if (RdM) 
					read_write = {1'b0, read_hit};
			end else begin
				Current_MESI_state_proc = I;
				if (WrM) begin
					bus_message_o = bus_write_miss;
					read_write = {1'b0, write_miss};
				end else if (RdM) begin
					bus_message_o = bus_read_miss;
					if (seen_i) begin
						read_write = { shared || bus_response_valid ,read_miss};
						if ( shared ) bus_message_o = NA;
					end
				end
			end
		end else begin 
			prior = 1'b0;
			if (seen_i) bus_message_o = NA;
		end
	end
	

	always_comb begin
		{tag_snoop, index_snoop} = 4'b0;
		hit_snoop = 1'b0;
		shared = 1'b0;
		seen_o = 1'b0;
		bus_data_valid = 1'b0;
		Current_MESI_state_snoop = cache[index_snoop][35:34];
		message_i = NA;

		if ( bus_message_i != NA) begin
			message_i = bus_message_i;
			seen_o = 1'b1;
			hit_snoop = cache[bus_addr_i[1:0]][33:32]==bus_addr_i[3:2];
			if (hit_snoop) begin
				{tag_snoop, index_snoop} = bus_addr_i;
				if (tag_snoop == tag_proc && active) begin
					shared = 1'b1;
				end
				
				if( bus_message_i == bus_read_miss ) begin
					bus_data_valid = (Current_MESI_state_snoop!=I);
				end
			end
		end
	end


   
	/**********************************************************************************
						MESI mesi DIAGRAM IMPLEMENTATION - Processor
	**********************************************************************************/
	action cc(Current_MESI_state_proc, read_write, mem_rden_proc, Updated_MESI_state_proc); 


	/*******************************************************************************
                   MESI mesi DIAGRAM IMPLEMENTATION - Snoop
	*******************************************************************************/
	snoop sn(Current_MESI_state_snoop, message_i, mem_wren_snoop, Updated_MESI_state_snoop); //snooper

	
	logic [1:0] index;
	//main body
	always_comb begin 
		//
		mem_rden = mem_rden_proc && !bus_response_valid; // abort mem access if other proc has required data
		//
		mem_wren = ( ( read_write == write_miss || bus_message_i == bus_read_miss ) && ( cache[index_proc][35:34] == M ) ) ? 1'b1 : mem_wren_snoop;

		Addr_rq = active ? AdrM_i : hit_snoop ? bus_addr_i : 4'b0;
		data_o  = cache[index][31:0];
	end
	
	//cache address-data update
	always @(posedge clk) begin
		if (active) begin
			AdrM 				 <= AdrM_i;
			index 				 <= AdrM_i[1:0];
		end else begin
			index 			     <= bus_addr_i[1:0];
		end

		bus_response_valid_q   	 <= bus_response_valid;	
		if (prior) begin
			cache[index_proc][35:34] <= Updated_MESI_state_proc;
		end
		
		if ( !prior || index_snoop != index_proc ) begin
			cache[index_snoop][35:34] <= Updated_MESI_state_snoop;
		end		

		if (WrM) begin
			wd_q = WriteDataM;
			wrAdr_q = AdrM_i[3:2];
		end

		
		if (we_q) begin
			cache[index_proc[1:0]][33:0] <= {wrAdr_q, wd_q};
		end else if (bus_response_valid_q) begin
			cache[index_proc[1:0]][33:0] <= {AdrM[3:2], bus_data_i};
		end else if (mmvalid) begin
			cache[index_proc[1:0]][33:0] <= {mmtag, mmdata};
		end
	end

	always_ff @( negedge clk ) begin 
		we_q <= WrM;
	end
	
endmodule
