module bus_rq_controller(

	input logic [1:0] status__q,
	input logic bus_write_miss, 
	input logic bus_read_miss, 
	input logic bus_invalidate,
	
	output logic abort_mem_access_n,
	output logic write_back_block_n,
	output logic [1:0] status_n
	);

	parameter I=2'b00, M=2'b01, S=2'b10;
    
	initial begin 
		status_n <= I;
		write_back_block_n <= 0;
		abort_mem_access_n <= 0;
	end

	always@(*)begin
		case(status__q)
			M:begin
				case({bus_write_miss,bus_read_miss})
					2'b01:begin
						status_n <= S;
						write_back_block_n <= 1;
						abort_mem_access_n <= 1;
					end
					2'b10:begin
						status_n <= I;
						write_back_block_n <= 1;
						abort_mem_access_n <= 1;
					end
					default: begin
						status_n <= status_n; 
					 	write_back_block_n <= 0;
					 	abort_mem_access_n <= 0;
					end
				endcase
			end
			S:begin
				case({bus_invalidate,bus_write_miss,bus_read_miss})
					3'b001:begin
						status_n <= S;
						write_back_block_n <= 0;
						abort_mem_access_n <= 0;
					end
					3'b010,3'b100:begin
						status_n <= I;
						write_back_block_n <= 0;
						abort_mem_access_n <= 0;
					end
					default:begin
					 	write_back_block_n <= 0;
					 	abort_mem_access_n <= 0;
					 	status_n <= status_n;
					end
				endcase
			end
		endcase
	end
endmodule
