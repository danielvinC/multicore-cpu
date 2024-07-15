module dmem(
	input logic clk,
	//from cpu
	input logic read, write, 
	input logic [31:0] write_data,
	input logic [3:0] mem_address,
	
	input logic [1:0] bus_requests,//from other caches: bus_invalidate=2'b00, bus_write_miss=2'b01, bus_read_miss=2'b10;
	input logic [3:0] bus_request_mem_address,//the position they reffer	
	
	input logic bus_data_found,//if the other cache says abort mem access 
	input logic [31:0] bus_data_delivery,//if we ever need a data that's in other cache, there it is
	
	input logic [31:0] mem_data_delivery,
    input logic [1:0] tag_bit,
	
	output logic [31:0] data_out_cpu,//reading going to cpu 

	output logic cpu_write_back, bus_write_back,//promote upper in the hierarchy, main mem is watching this
	output logic [3:0] address_out_mem_cpu,address_out_mem_bus,
	output logic [31:0] data_out_mem_cpu,data_out_mem_bus,//unique data goes to ram

	output logic bus_reply_abort_mem_access,//announces to the other core we have the data needed
	output logic [31:0] bus_reply_data_found,//attends bus_request
	
	output logic [3:0] ask_mem_address,//what they need to find
	output logic [1:0] bus_reply//write on bus for another core that's snooping it
	);

    // Cache Line Configuration Scheme:
    // |coherency state ~2bits|tag ~2bits|data ~32bits|
    //  35                  34 33      32 31         0
	integer i;//inicialization
	integer j,k;//loops
	
	//States parameters, for status_q and state_out, simplificam a vida:
	parameter I=2'b00, M=2'b01, S=2'b10;
	//Bus parameters, to go out for bus:
	parameter bus_invalidate=2'b00, bus_write_miss=2'b01, bus_read_miss=2'b10;
	
	logic [35:0] cache [3:0];//estrutura de dados da cache que armazenara o que a fsm r e b retorna
	
	logic [1:0] cache_index;
	assign cache_index = mem_address[1:0];//decomposing the cpu address input into index and tag
	logic [1:0] tag;
	assign tag = mem_address[3:2];

	logic [1:0] cache_tag_attending_bus;
	assign cache_tag_attending_bus = bus_request_mem_address[3:2];//decomposing the bus address input into index and tag
	logic [1:0] cache_index_attending_bus;
	assign cache_index_attending_bus = bus_request_mem_address[1:0];
	logic [1:0] coherency_state_attending_bus;
	assign coherency_state_attending_bus = cache[cache_index_attending_bus][35:34];

	logic [1:0] coherency_state_attending_cpu;
	assign coherency_state_attending_cpu = cache[cache_index][35:34];//decomposing cache's line
	logic [1:0] mem_tag;
	assign mem_tag = cache[cache_index][33:32];
	logic [31:0] data;
	assign data = cache[cache_index][31:0];

	logic write_hit, write_miss, read_hit, read_miss, bus_resquest_match, cpu_controler_write_back;

	assign write_hit  = (write) & ( mem_tag == tag) & coherency_state_attending_cpu!=I;//for calculating the next block state
	assign write_miss = (write) & ((mem_tag != tag) | coherency_state_attending_cpu==I);
	assign read_hit   = (read ) & ( mem_tag == tag) & coherency_state_attending_cpu!=I;
	assign read_miss  = (read ) & ((mem_tag != tag) | coherency_state_attending_cpu==I);

	assign bus_resquest_match = (cache[cache_index_attending_bus][35:34]!=I) & (cache[cache_index_attending_bus][33:32]==cache_tag_attending_bus);
	logic bus_controler_abort_mem_access;
	logic [1:0] status_n_cpu,status_n_bus;//first is used in the block, the second is what our FSI MSI BUS calculated to attend bus a request
	
	assign data_out_cpu = read_hit ? data : (bus_data_found ? bus_data_delivery : mem_data_delivery);

	assign cpu_write_back = cpu_controler_write_back;
	assign bus_write_back = bus_controler_write_back;

	assign address_out_mem_cpu = {cache[cache_index][33:32],cache_index};
	assign address_out_mem_bus =  {cache[cache_index_attending_bus][33:32],cache_index_attending_bus};
	assign data_out_mem_cpu = cache[cache_index][31:0];
	assign data_out_mem_bus = cache[cache_index_attending_bus][31:0];

	assign bus_reply_abort_mem_access = bus_resquest_match ? bus_controler_abort_mem_access : 1'b0;
	assign bus_reply_data_found = cache[cache_index_attending_bus][31:0];//think as abort mem access data

	assign ask_mem_address = mem_address;

	initial begin		
		#0
		for(i=0;i<4;i=i+1) begin
			cache[i]<=35'b0;
		end
	end

	cpu_rq_controller _CTRL_R_(
		.status_q(coherency_state_attending_cpu),
		.cpu_write_hit(write_hit),.cpu_read_hit(read_hit),
		.cpu_write_miss(write_miss),.cpu_read_miss(read_miss),
		.write_back_block_n(cpu_controler_write_back),//send to mem //<-outputs:
		.status_n(status_n_cpu),//used in block
		.bus_n(bus_reply)//writen on bus
	);
	bus_rq_controller _CTRL_B_(
		.status__q(coherency_state_attending_bus),
		.bus_write_miss(bus_requests==bus_write_miss), 
		.bus_read_miss(bus_requests==bus_read_miss), 
		.bus_invalidate(bus_requests==bus_invalidate),	
		.abort_mem_access_n(bus_controler_abort_mem_access),//send to bus //<-outputs:
		.write_back_block_n(bus_controler_write_back),//send to mem
		.status_n(status_n_bus)//used on block
	);

	always@(posedge clk)begin
		cache[cache_index][21:20] <= status_n_cpu;//update line state from cpu request
		if (bus_resquest_match==1'b1)begin
			cache[cache_index_attending_bus][21:20] <= status_n_bus;//update line state from bus request
		end
		if(write==1'b1)begin
			cache[cache_index][31:0] <= write_data;
		end
		if (bus_data_found==1'b1 && read_miss == 1'b1)begin
			cache[cache_index][31:0] <= bus_data_delivery;
		    cache[cache_index][33:32] <= cache_tag_attending_bus;
		end 
		else if (bus_data_found==1'b0 && read_miss == 1'b1)begin
			cache[cache_index][31:0] <= mem_data_delivery;
            cache[cache_index][33:32] <= tag_bit;
		end
	end
endmodule