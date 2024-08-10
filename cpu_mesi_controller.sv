module action(
	input logic [1:0] status_q,
	input logic [2:0] read_write,

	output logic rden,
	output logic [1:0] status_n
	);

	//States parameters, for status_q and state_out, simplificam a vida:
	parameter I=2'b00, M=2'b01, S=2'b10, E=2'b11;
	//action parametor
	parameter write_hit = 3'b000, read_hit = 3'b001, write_miss = 3'b010, read_miss_exclusive = 3'b011, read_miss_share = 3'b100;
		
	always_comb begin : coherency_controller
		//default
		status_n = status_q;
		rden = 1'b0;
		case(status_q)
			M:begin
				if(read_write==write_hit || read_write==read_hit) begin
					status_n = M;
				end 
			end
			E:begin
				if(read_write==read_hit) begin 
					status_n = E;
				end else if (read_write==write_hit) begin
					status_n = M;
				end 
			end
			S:begin
				if (read_write==read_hit) begin
					status_n = S;
				end
				else if (read_write==write_hit) begin
					status_n = M;
				end
			end
			I:begin
				if (read_write==read_miss_share) begin
					status_n = S;
					rden = 1'b1;
				end
				if (read_write==read_miss_exclusive) begin
					status_n = E;
					rden = 1'b1;
				end
				else if (read_write==write_miss) begin
					status_n = M;
				end			
			end
		endcase
	end
endmodule
